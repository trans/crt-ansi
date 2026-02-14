module CRT::Ansi
  # A virtual buffer larger than the visible area, for scrollable content.
  #
  # Has the same drawing API as Render (via Canvas): `put`, `write`,
  # `clear`, `cell`, `box`, `panel`. Use `blit` on the target to
  # copy a visible window from the viewport.
  #
  # ```
  # vp = Viewport.new(width: 80, height: 200)
  # vp.write(0, 150, "way down here", style)
  # render.blit(vp, x: 5, y: 3, w: 20, h: 10, scroll_y: 140)
  # ```
  class Viewport
    include Canvas

    getter width : Int32
    getter height : Int32

    def initialize(width : Int, height : Int, *, context : Context = CRT::Ansi.context)
      @width = width.to_i
      @height = height.to_i
      @buffer = Buffer.new(width, height, context: context)
    end

    def default_style : Style
      @buffer.default_style
    end

    def put(x : Int, y : Int, grapheme : String, style : Style = default_style) : Nil
      @buffer.put(x, y, grapheme, style)
    end

    def write(x : Int, y : Int, text : String, style : Style = default_style) : Int32
      @buffer.write(x, y, text, style)
    end

    def clear(style : Style = default_style) : Nil
      @buffer.clear(style)
    end

    def cell(x : Int, y : Int) : Cell
      @buffer.cell(x, y)
    end

    def resize(width : Int, height : Int, *, context : Context = CRT::Ansi.context) : Nil
      @width = width.to_i
      @height = height.to_i
      @buffer = Buffer.new(width, height, context: context)
    end
  end
end
