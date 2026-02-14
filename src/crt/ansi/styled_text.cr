module CRT::Ansi
  struct Style
    # An array of styled text spans for rich text rendering.
    #
    # Build from an array of parts — a mini-DSL for styled text:
    #
    # ```
    # bold = Style.new(bold: true)
    # red = Style.new(fg: Color.indexed(1))
    #
    # text = Style::Text.new([
    #   "plain ", bold, "bold ", red, "bold+red",
    #   Style::POP, " bold again",
    #   Style::RESET, " back to default",
    # ] of Style::Text::Part)
    # ```
    #
    # Part types:
    # - `String` — text content, styled by the current stack top
    # - `Style` — merge onto style stack (additive)
    # - `Style::Char` — emit its char with its own style
    # - `Style::Text` — splice its spans in verbatim
    # - `POP` — pop the style stack
    # - `RESET` — clear the stack back to default
    struct Text
      record Span, text : String, style : Style

      enum Control
        Pop
        Reset
      end

      alias Part = String | Style | Style::Char | Text | Control

      getter spans : Array(Span)

      def initialize
        @spans = [] of Span
      end

      def initialize(@spans : Array(Span))
      end

      def initialize(parts : Array(Part), default : Style = Style.default)
        @spans = [] of Span
        stack = [default]

        parts.each do |part|
          case part
          when String
            @spans << Span.new(part, stack.last) unless part.empty?
          when Style
            stack << stack.last.merge(part)
          when Style::Char
            @spans << Span.new(part.char, part.style)
          when Text
            @spans.concat(part.spans)
          when Control
            case part
            in .pop?
              stack.pop if stack.size > 1
            in .reset?
              stack.clear
              stack << default
            end
          end
        end
      end

      def add(text : String, style : Style = Style.default) : self
        @spans << Span.new(text, style)
        self
      end

      # Total display width of all spans.
      def width : Int32
        total = 0
        each_grapheme { |_, gw, _| total += gw }
        total
      end

      # Iterate over each grapheme with its width and style.
      def each_grapheme(& : String, Int32, Style ->) : Nil
        @spans.each do |span|
          Graphemes.each(span.text) do |grapheme|
            yield grapheme, DisplayWidth.of(grapheme), span.style
          end
        end
      end

      # Plain text content (all spans concatenated).
      def to_s(io : IO) : Nil
        @spans.each { |span| io << span.text }
      end

      def to_s : String
        String.build { |io| to_s(io) }
      end

      def empty? : Bool
        @spans.all? { |span| span.text.empty? }
      end
    end

    POP   = Text::Control::Pop
    RESET = Text::Control::Reset
  end
end
