module CRT::Ansi
  struct Key
    enum Code
      # Printable character (stored in @char)
      Char

      # Whitespace / editing
      Enter
      Tab
      Backspace
      Delete
      Insert
      Escape

      # Navigation
      Up
      Down
      Left
      Right
      Home
      End
      PageUp
      PageDown

      # Function keys
      F1; F2; F3; F4; F5; F6; F7; F8; F9; F10; F11; F12
    end

    getter code : Code
    getter char : String
    getter? shift : Bool
    getter? alt : Bool
    getter? ctrl : Bool

    def initialize(@code : Code, @char : String = "", *,
                   @shift : Bool = false, @alt : Bool = false, @ctrl : Bool = false)
    end

    def self.char(ch : Char | String, *, shift = false, alt = false, ctrl = false) : self
      new(Code::Char, ch.to_s, shift: shift, alt: alt, ctrl: ctrl)
    end

    def self.ctrl(ch : Char) : self
      new(Code::Char, ch.to_s, ctrl: true)
    end

    def char? : Bool
      @code.char?
    end

    def ==(other : Key) : Bool
      @code == other.code && @char == other.char &&
        @shift == other.shift? && @alt == other.alt? && @ctrl == other.ctrl?
    end

    def to_s(io : IO) : Nil
      if @ctrl
        io << "Ctrl+"
      end
      if @alt
        io << "Alt+"
      end
      if @shift
        io << "Shift+"
      end
      if @code.char?
        io << @char
      else
        io << @code
      end
    end
  end
end
