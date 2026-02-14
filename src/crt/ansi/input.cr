module CRT::Ansi
  class Input
    def initialize(@io : IO)
      @buf = Bytes.new(64)
      @pos = 0
      @len = 0
    end

    # Read the next input event (blocking). Returns Key or Mouse.
    def read_event : Event?
      byte = read_byte
      return nil unless byte

      case byte
      when 0x01..0x07, 0x0e..0x1a
        Key.ctrl(('a'.ord + byte - 1).chr)
      when 0x08
        Key.new(Key::Code::Backspace)
      when 0x09
        Key.new(Key::Code::Tab)
      when 0x0a, 0x0d
        Key.new(Key::Code::Enter)
      when 0x1b
        parse_escape
      when 0x7f
        Key.new(Key::Code::Backspace)
      else
        parse_char(byte)
      end
    end

    # Read the next key event (blocking). Discards mouse events.
    def read_key : Key?
      loop do
        event = read_event
        return nil unless event
        return event if event.is_a?(Key)
      end
    end

    # Return the next event if input is available, nil otherwise.
    # Never blocks — suitable for frame-rate-based loops.
    def poll_event : Event?
      return read_event if @pos < @len

      if @io.is_a?(IO::FileDescriptor)
        return nil unless wait_for_data(@io.as(IO::FileDescriptor), Time::Span.zero)
      end

      read_event
    end

    private def parse_escape : Event
      b = peek_byte(timeout: 50.milliseconds)

      # Bare ESC (no followup within timeout)
      return Key.new(Key::Code::Escape) unless b

      case b
      when 0x5b # '['
        consume_byte
        parse_csi
      when 0x4f # 'O'
        consume_byte
        parse_ss3
      when 0x1b
        consume_byte
        Key.new(Key::Code::Escape)
      else
        # Alt+key
        consume_byte
        key = parse_byte(b)
        Key.new(key.code, key.char, alt: true)
      end
    end

    private def parse_csi : Event
      # Check for SGR mouse: ESC[< ...
      first = peek_buffered_byte
      if first == 0x3c # '<'
        consume_byte
        return parse_sgr_mouse
      end

      # Accumulate parameter bytes (digits and semicolons) then final byte
      params = String::Builder.new
      loop do
        b = read_byte
        return Key.new(Key::Code::Escape) unless b

        if b >= 0x30 && b <= 0x3f # '0'..'?'  (parameter bytes)
          params << b.chr
        elsif b >= 0x20 && b <= 0x2f # intermediate bytes
          params << b.chr
        elsif b >= 0x40 && b <= 0x7e # final byte
          return decode_csi(params.to_s, b.chr)
        else
          return Key.new(Key::Code::Escape)
        end
      end
    end

    # SGR mouse: ESC[< button;x;y M/m
    # button encoding: bits 0-1 = button, bit 5 = motion, bit 6 = scroll
    # Final byte: M = press/motion, m = release
    private def parse_sgr_mouse : Event
      params = String::Builder.new
      loop do
        b = read_byte
        return Key.new(Key::Code::Escape) unless b

        if b.chr == 'M' || b.chr == 'm'
          return decode_sgr_mouse(params.to_s, b.chr)
        else
          params << b.chr
        end
      end
    end

    private def decode_sgr_mouse(params : String, final : Char) : Event
      parts = params.split(';')
      return Key.new(Key::Code::Escape) unless parts.size == 3

      code = parts[0].to_i? || return Key.new(Key::Code::Escape)
      x = (parts[1].to_i? || return Key.new(Key::Code::Escape)) - 1  # 1-indexed → 0-indexed
      y = (parts[2].to_i? || return Key.new(Key::Code::Escape)) - 1

      shift = (code & 4) != 0
      alt = (code & 8) != 0
      ctrl = (code & 16) != 0

      button_code = code & 0x43  # bits 0-1 + bit 6
      is_motion = (code & 32) != 0

      action = if is_motion
                 Mouse::Action::Motion
               elsif final == 'm'
                 Mouse::Action::Release
               else
                 Mouse::Action::Press
               end

      button = case button_code
               when 0  then Mouse::Button::Left
               when 1  then Mouse::Button::Middle
               when 2  then Mouse::Button::Right
               when 3  then Mouse::Button::None  # release in some encodings
               when 64 then Mouse::Button::ScrollUp
               when 65 then Mouse::Button::ScrollDown
               when 66 then Mouse::Button::ScrollLeft
               when 67 then Mouse::Button::ScrollRight
               else         Mouse::Button::None
               end

      Mouse.new(button, action, x, y, shift: shift, alt: alt, ctrl: ctrl)
    end

    private def decode_csi(params : String, final : Char) : Key
      parts = params.split(';')
      modifier = parse_modifier(parts[1]?) if parts.size > 1

      shift = modifier.try(&.[:shift]) || false
      alt = modifier.try(&.[:alt]) || false
      ctrl = modifier.try(&.[:ctrl]) || false

      case final
      when 'A' then Key.new(Key::Code::Up, shift: shift, alt: alt, ctrl: ctrl)
      when 'B' then Key.new(Key::Code::Down, shift: shift, alt: alt, ctrl: ctrl)
      when 'C' then Key.new(Key::Code::Right, shift: shift, alt: alt, ctrl: ctrl)
      when 'D' then Key.new(Key::Code::Left, shift: shift, alt: alt, ctrl: ctrl)
      when 'H' then Key.new(Key::Code::Home, shift: shift, alt: alt, ctrl: ctrl)
      when 'F' then Key.new(Key::Code::End, shift: shift, alt: alt, ctrl: ctrl)
      when 'P' then Key.new(Key::Code::F1, shift: shift, alt: alt, ctrl: ctrl)
      when 'Q' then Key.new(Key::Code::F2, shift: shift, alt: alt, ctrl: ctrl)
      when 'R' then Key.new(Key::Code::F3, shift: shift, alt: alt, ctrl: ctrl)
      when 'S' then Key.new(Key::Code::F4, shift: shift, alt: alt, ctrl: ctrl)
      when '~'
        decode_tilde(parts[0]?, shift: shift, alt: alt, ctrl: ctrl)
      else
        Key.new(Key::Code::Escape)
      end
    end

    private def decode_tilde(param : String?, *, shift : Bool, alt : Bool, ctrl : Bool) : Key
      case param
      when "1"  then Key.new(Key::Code::Home, shift: shift, alt: alt, ctrl: ctrl)
      when "2"  then Key.new(Key::Code::Insert, shift: shift, alt: alt, ctrl: ctrl)
      when "3"  then Key.new(Key::Code::Delete, shift: shift, alt: alt, ctrl: ctrl)
      when "4"  then Key.new(Key::Code::End, shift: shift, alt: alt, ctrl: ctrl)
      when "5"  then Key.new(Key::Code::PageUp, shift: shift, alt: alt, ctrl: ctrl)
      when "6"  then Key.new(Key::Code::PageDown, shift: shift, alt: alt, ctrl: ctrl)
      when "11" then Key.new(Key::Code::F1, shift: shift, alt: alt, ctrl: ctrl)
      when "12" then Key.new(Key::Code::F2, shift: shift, alt: alt, ctrl: ctrl)
      when "13" then Key.new(Key::Code::F3, shift: shift, alt: alt, ctrl: ctrl)
      when "14" then Key.new(Key::Code::F4, shift: shift, alt: alt, ctrl: ctrl)
      when "15" then Key.new(Key::Code::F5, shift: shift, alt: alt, ctrl: ctrl)
      when "17" then Key.new(Key::Code::F6, shift: shift, alt: alt, ctrl: ctrl)
      when "18" then Key.new(Key::Code::F7, shift: shift, alt: alt, ctrl: ctrl)
      when "19" then Key.new(Key::Code::F8, shift: shift, alt: alt, ctrl: ctrl)
      when "20" then Key.new(Key::Code::F9, shift: shift, alt: alt, ctrl: ctrl)
      when "21" then Key.new(Key::Code::F10, shift: shift, alt: alt, ctrl: ctrl)
      when "23" then Key.new(Key::Code::F11, shift: shift, alt: alt, ctrl: ctrl)
      when "24" then Key.new(Key::Code::F12, shift: shift, alt: alt, ctrl: ctrl)
      else
        Key.new(Key::Code::Escape)
      end
    end

    private def parse_ss3 : Key
      b = read_byte
      return Key.new(Key::Code::Escape) unless b

      case b.chr
      when 'A' then Key.new(Key::Code::Up)
      when 'B' then Key.new(Key::Code::Down)
      when 'C' then Key.new(Key::Code::Right)
      when 'D' then Key.new(Key::Code::Left)
      when 'H' then Key.new(Key::Code::Home)
      when 'F' then Key.new(Key::Code::End)
      when 'P' then Key.new(Key::Code::F1)
      when 'Q' then Key.new(Key::Code::F2)
      when 'R' then Key.new(Key::Code::F3)
      when 'S' then Key.new(Key::Code::F4)
      else
        Key.new(Key::Code::Escape)
      end
    end

    # Xterm modifier encoding: parameter = 1 + bitmask
    # Bit 0 = shift, Bit 1 = alt, Bit 2 = ctrl
    private def parse_modifier(param : String?) : NamedTuple(shift: Bool, alt: Bool, ctrl: Bool)?
      return nil unless param
      n = param.to_i? || return nil
      n -= 1
      {shift: (n & 1) != 0, alt: (n & 2) != 0, ctrl: (n & 4) != 0}
    end

    private def parse_char(byte : UInt8) : Key
      if byte < 0x80
        Key.char(byte.chr)
      elsif byte < 0xc0
        Key.char(byte.chr)
      else
        needed = case byte
                 when .< 0xe0 then 1
                 when .< 0xf0 then 2
                 else              3
                 end

        bytes = Bytes.new(needed + 1)
        bytes[0] = byte
        needed.times do |i|
          b = read_byte
          return Key.char('\u{FFFD}') unless b
          bytes[i + 1] = b
        end

        str = String.new(bytes)
        Key.char(str)
      end
    end

    private def parse_byte(byte : UInt8) : Key
      case byte
      when 0x08, 0x7f then Key.new(Key::Code::Backspace)
      when 0x09       then Key.new(Key::Code::Tab)
      when 0x0a, 0x0d then Key.new(Key::Code::Enter)
      else                 parse_char(byte)
      end
    end

    # --- Low-level byte reading ---

    private def read_byte : UInt8?
      if @pos < @len
        b = @buf[@pos]
        @pos += 1
        return b
      end

      n = @io.read(@buf)
      return nil if n == 0

      @pos = 1
      @len = n
      @buf[0]
    end

    private def consume_byte : Nil
      read_byte
    end

    # Peek at the next buffered byte without consuming (no IO read).
    private def peek_buffered_byte : UInt8?
      @pos < @len ? @buf[@pos] : nil
    end

    # Peek at next byte with timeout. Returns nil if no data arrives.
    private def peek_byte(timeout : Time::Span) : UInt8?
      if @pos < @len
        return @buf[@pos]
      end

      if @io.is_a?(IO::FileDescriptor)
        fd = @io.as(IO::FileDescriptor)
        if wait_for_data(fd, timeout)
          n = @io.read(@buf)
          if n > 0
            @pos = 0
            @len = n
            return @buf[0]
          end
        end
        return nil
      end

      n = @io.read(@buf)
      return nil if n == 0
      @pos = 0
      @len = n
      @buf[0]
    end

    private def wait_for_data(fd : IO::FileDescriptor, timeout : Time::Span) : Bool
      {% if flag?(:unix) %}
        pollfd = LibC::PollFD.new
        pollfd.fd = fd.fd
        pollfd.events = LibC::POLLIN
        ms = timeout.total_milliseconds.to_i
        ret = LibC.poll(pointerof(pollfd), 1, ms)
        ret > 0
      {% else %}
        true
      {% end %}
    end
  end
end

{% if flag?(:unix) %}
  lib LibC
    POLLIN = 0x0001

    struct PollFD
      fd : Int
      events : Short
      revents : Short
    end

    {% unless LibC.has_method?(:poll) %}
      fun poll(fds : PollFD*, nfds : ULong, timeout : Int) : Int
    {% end %}
  end
{% end %}
