module CRT::Ansi
  # An array of styled text spans for rich text rendering.
  #
  # Build from an array of parts — a mini-DSL for styled text:
  #
  # ```
  # bold = Style.new(bold: true)
  # red = Style.new(fg: Color.indexed(1))
  #
  # text = StyledText.new([
  #   "plain ", bold, "bold ", red, "bold+red",
  #   StyledText::POP, " bold again",
  #   StyledText::RESET, " back to default",
  # ] of StyledText::Part)
  # ```
  #
  # Part types:
  # - `String` — text content, styled by the current stack top
  # - `Style` — merge onto style stack (additive)
  # - `StyleChar` — emit its char with its own style
  # - `StyledText` — splice its spans in verbatim
  # - `POP` — pop the style stack
  # - `RESET` — clear the stack back to default
  struct StyledText
    record Span, text : String, style : Style

    enum Control
      Pop
      Reset
    end

    POP   = Control::Pop
    RESET = Control::Reset

    alias Part = String | Style | StyleChar | StyledText | Control

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
        when StyleChar
          @spans << Span.new(part.char, part.style)
        when StyledText
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
end
