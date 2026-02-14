module CRT::Ansi
  # An array of styled text spans for rich text rendering.
  #
  # ```
  # text = StyledText.new
  #   .add("Hello ", Style.new(bold: true))
  #   .add("world", Style.new(fg: Color.rgb(100, 200, 255)))
  # ```
  struct StyledText
    record Span, text : String, style : Style

    getter spans : Array(Span)

    def initialize
      @spans = [] of Span
    end

    def initialize(@spans : Array(Span))
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
