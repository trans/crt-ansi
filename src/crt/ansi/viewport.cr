module CRT::Ansi
  # A virtual buffer larger than the visible area, for scrollable content.
  #
  # Render into the viewport at any coordinate, then blit a visible
  # window onto a Renderer at a given scroll offset.
  #
  # ```
  # vp = Viewport.new(width: 80, height: 200)
  # vp.write(0, 150, "way down here", style)
  # vp.blit(renderer, x: 5, y: 3, w: 20, h: 10, scroll_y: 140)
  # ```
  class Viewport
    getter width : Int32
    getter height : Int32

    def initialize(width : Int, height : Int, *, context : Context = CRT::Ansi.context)
      @width = width.to_i
      @height = height.to_i
      @buffer = Buffer.new(width, height, context: context)
    end

    def put(x : Int, y : Int, grapheme : String, style : Style = Style.default) : Nil
      @buffer.put(x, y, grapheme, style)
    end

    def write(x : Int, y : Int, text : String, style : Style = Style.default) : Int32
      @buffer.write(x, y, text, style)
    end

    def clear(style : Style = Style.default) : Nil
      @buffer.clear(style)
    end

    def cell(x : Int, y : Int) : Cell
      @buffer.cell(x, y)
    end

    # Copy a visible window from this viewport onto a Renderer.
    #
    # - `x`, `y` — destination position on the renderer
    # - `w`, `h` — size of the visible window
    # - `scroll_x`, `scroll_y` — offset into the viewport buffer
    def blit(target : Renderer, *, x : Int, y : Int, w : Int, h : Int,
             scroll_x : Int = 0, scroll_y : Int = 0) : Nil
      sx = scroll_x.to_i
      sy = scroll_y.to_i
      bw = w.to_i
      bh = h.to_i
      tx = x.to_i
      ty = y.to_i

      bh.times do |row|
        src_y = sy + row
        next if src_y < 0 || src_y >= @height

        col = 0
        while col < bw
          src_x = sx + col
          if src_x < 0 || src_x >= @width
            col += 1
            next
          end

          c = @buffer.cell(src_x, src_y)
          unless c.continuation?
            target.put(tx + col, ty + row, c.grapheme, c.style)
          end
          col += 1
        end
      end
    end

    def resize(width : Int, height : Int, *, context : Context = CRT::Ansi.context) : Nil
      @width = width.to_i
      @height = height.to_i
      @buffer = Buffer.new(width, height, context: context)
    end
  end
end
