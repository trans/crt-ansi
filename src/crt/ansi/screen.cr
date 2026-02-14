{% if flag?(:unix) %}
  lib LibC
    struct Winsize
      ws_row : UInt16
      ws_col : UInt16
      ws_xpixel : UInt16
      ws_ypixel : UInt16
    end

    TIOCGWINSZ = 0x5413

    {% unless LibC.has_method?(:ioctl) %}
      fun ioctl(fd : Int, request : ULong, ...) : Int
    {% end %}
  end
{% end %}

module CRT::Ansi
  class Screen
    getter render : Renderer
    getter io : IO
    getter? running : Bool
    getter? alt_screen : Bool
    getter? raw_mode : Bool
    getter? cursor_hidden : Bool
    @resize_handler : Proc(Int32, Int32, Nil)? = nil
    @input : Input? = nil

    def initialize(
      @io : IO = STDOUT,
      *,
      alt_screen : Bool = true,
      raw_mode : Bool = true,
      hide_cursor : Bool = true,
      context : Context? = nil,
    )
      @context = context || Context.detect
      CRT::Ansi.context = @context

      w, h = detect_size
      @render = Renderer.new(@io, w, h, context: @context)
      @running = false
      @alt_screen = false
      @raw_mode = false
      @cursor_hidden = false
      @wants_alt_screen = alt_screen
      @wants_raw_mode = raw_mode
      @wants_hide_cursor = hide_cursor
    end

    def self.open(io : IO = STDOUT, **opts, &) : Nil
      screen = new(io, **opts)
      screen.start
      begin
        yield screen
      ensure
        screen.stop
      end
    end

    def start : Nil
      return if @running
      @running = true

      enter_alt_screen if @wants_alt_screen
      enter_raw_mode if @wants_raw_mode
      hide_cursor if @wants_hide_cursor
      install_resize_handler
      @io.flush
    end

    def stop : Nil
      return unless @running
      @running = false

      @render.reset_terminal_state!
      show_cursor if @cursor_hidden
      exit_alt_screen if @alt_screen
      exit_raw_mode if @raw_mode
      @io.flush
    end

    def width : Int32
      @render.width
    end

    def height : Int32
      @render.height
    end

    def on_resize(&handler : Int32, Int32 -> Nil) : Nil
      @resize_handler = handler
    end

    def resize(width : Int32, height : Int32) : Nil
      @render.resize(width, height)
    end

    def cursor(visible : Bool) : Nil
      if visible
        show_cursor
      else
        hide_cursor
      end
    end

    def present : Int32
      @render.present
    end

    # Read the next key event (blocking).
    def read_key : Key?
      input.read_key
    end

    def input : Input
      @input ||= Input.new(STDIN)
    end

    # Delegate drawing methods to the renderer.
    delegate :put, :write, :clear, :cell, to: @render

    private def enter_alt_screen : Nil
      @io << "\e[?1049h"
      @alt_screen = true
    end

    private def exit_alt_screen : Nil
      @io << "\e[?1049l"
      @alt_screen = false
    end

    private def hide_cursor : Nil
      @io << "\e[?25l"
      @cursor_hidden = true
    end

    private def show_cursor : Nil
      @io << "\e[?25h"
      @cursor_hidden = false
    end

    private def enter_raw_mode : Nil
      if @io.is_a?(IO::FileDescriptor)
        @io.as(IO::FileDescriptor).raw!
        @raw_mode = true
      end
    end

    private def exit_raw_mode : Nil
      if @io.is_a?(IO::FileDescriptor) && @raw_mode
        @io.as(IO::FileDescriptor).cooked!
        @raw_mode = false
      end
    end

    private def detect_size : {Int32, Int32}
      {% if flag?(:unix) %}
        if @io.is_a?(IO::FileDescriptor)
          fd = @io.as(IO::FileDescriptor).fd
          ws = uninitialized LibC::Winsize
          if LibC.ioctl(fd, LibC::TIOCGWINSZ, pointerof(ws)) == 0
            return {ws.ws_col.to_i32, ws.ws_row.to_i32}
          end
        end
      {% end %}
      {80, 24}
    end

    private def install_resize_handler : Nil
      Signal::WINCH.trap do
        w, h = detect_size
        @render.resize(w, h)
        if handler = @resize_handler
          handler.call(w, h)
        end
      end
    end
  end
end
