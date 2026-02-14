module CRT::Ansi
  struct Cell
    SPACE = " "

    getter grapheme : String
    getter style : Style
    getter width : Int32
    getter continuation : Bool

    def initialize(
      @grapheme : String = SPACE,
      @style : Style = Style.default,
      @width : Int32 = 1,
      @continuation : Bool = false,
    )
    end

    def self.blank(style : Style = Style.default) : self
      new(grapheme: SPACE, style: style, width: 1, continuation: false)
    end

    def self.continuation(style : Style = Style.default) : self
      new(grapheme: "", style: style, width: 0, continuation: true)
    end

    def continuation? : Bool
      @continuation
    end

    def blank? : Bool
      !@continuation && @width == 1 && @grapheme == SPACE
    end
  end
end
