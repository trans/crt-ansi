module CRT::Ansi
  struct Style
    getter fg : Color
    getter bg : Color

    getter bold : Bool
    getter dim : Bool
    getter italic : Bool
    getter underline : Bool
    getter blink : Bool
    getter inverse : Bool
    getter strikethrough : Bool

    getter hyperlink : Hyperlink?

    DEFAULT = Style.new

    def initialize(
      @fg : Color = Color.default,
      @bg : Color = Color.default,
      @bold : Bool = false,
      @dim : Bool = false,
      @italic : Bool = false,
      @underline : Bool = false,
      @blink : Bool = false,
      @inverse : Bool = false,
      @strikethrough : Bool = false,
      @hyperlink : Hyperlink? = nil,
    )
    end

    def self.default : self
      DEFAULT
    end

    def with_fg(color : Color) : self
      copy_with(fg: color)
    end

    def with_bg(color : Color) : self
      copy_with(bg: color)
    end

    def with_hyperlink(uri : String, id : String? = nil) : self
      copy_with(hyperlink: Hyperlink.new(uri, id))
    end

    def without_hyperlink : self
      copy_with(hyperlink: nil)
    end

    def append_sgr(io : IO, capabilities : Capabilities = CRT::Ansi.context.capabilities) : Nil
      io << "\e[0"
      io << ";1" if @bold && capabilities.bold
      io << ";2" if @dim && capabilities.dim
      io << ";3" if @italic && capabilities.italic
      io << ";4" if @underline && capabilities.underline
      io << ";5" if @blink && capabilities.blink
      io << ";7" if @inverse && capabilities.inverse
      io << ";9" if @strikethrough && capabilities.strikethrough

      if capabilities.color? && !@fg.default?
        io << ';'
        @fg.append_fg_sgr(io, capabilities)
      end

      if capabilities.color? && !@bg.default?
        io << ';'
        @bg.append_bg_sgr(io, capabilities)
      end

      io << 'm'
    end

    private def copy_with(
      fg : Color = @fg,
      bg : Color = @bg,
      bold : Bool = @bold,
      dim : Bool = @dim,
      italic : Bool = @italic,
      underline : Bool = @underline,
      blink : Bool = @blink,
      inverse : Bool = @inverse,
      strikethrough : Bool = @strikethrough,
      hyperlink : Hyperlink? = @hyperlink,
    ) : self
      Style.new(
        fg: fg,
        bg: bg,
        bold: bold,
        dim: dim,
        italic: italic,
        underline: underline,
        blink: blink,
        inverse: inverse,
        strikethrough: strikethrough,
        hyperlink: hyperlink
      )
    end
  end
end
