module CRT::Ansi
  # Shared drawing interface for Render and Viewport.
  #
  # Provides the common API: `put`, `write`, `clear`, `cell`,
  # `box`, `panel`, and `blit`. Includers implement the abstract
  # methods; the concrete methods build on them.
  module Canvas
    abstract def put(x : Int, y : Int, grapheme : String, style : Style) : Nil
    abstract def write(x : Int, y : Int, text : String, style : Style) : Int32
    abstract def clear(style : Style) : Nil
    abstract def cell(x : Int, y : Int) : Cell
    abstract def width : Int32
    abstract def height : Int32
    abstract def default_style : Style

    # Returns a Panel builder for fluid drawing within a region.
    def panel(x : Int, y : Int, *, w : Int, h : Int) : Panel
      Panel.new(self, x.to_i, y.to_i, w: w.to_i, h: h.to_i)
    end

    # Draw a box, horizontal line, or vertical line.
    #
    # - `w > 0` and `h > 0`: bordered box (w wide, h tall, inclusive)
    # - `w > 0` and `h == 0`: horizontal line of length w
    # - `w == 0` and `h > 0`: vertical line of length h
    def box(x : Int, y : Int, *, w : Int = 0, h : Int = 0,
            style : Style = default_style,
            border : Border = Border::Single,
            fill : Style | Style::Char | Nil = nil) : Nil
      hz, vt, tl, tr, bl, br = border.chars

      if w > 0 && h > 0
        put(x, y, tl, style)
        (w - 2).times { |i| put(x + i + 1, y, hz, style) }
        put(x + w - 1, y, tr, style)

        fill_char, fill_style = case fill
                                in Style    then {" ", fill}
                                in Style::Char then {fill.char, fill.style}
                                in Nil       then {nil, nil}
                                end

        (h - 2).times do |j|
          row = y + j + 1
          put(x, row, vt, style)
          if fill_char && fill_style
            (w - 2).times { |i| put(x + i + 1, row, fill_char, fill_style) }
          end
          put(x + w - 1, row, vt, style)
        end

        put(x, y + h - 1, bl, style)
        (w - 2).times { |i| put(x + i + 1, y + h - 1, hz, style) }
        put(x + w - 1, y + h - 1, br, style)
      elsif w > 0
        w.times { |i| put(x + i, y, hz, style) }
      elsif h > 0
        h.times { |j| put(x, y + j, vt, style) }
      end
    end

    # Copy a visible window from a source canvas onto this one.
    #
    # - `x`, `y` — destination position on this canvas
    # - `w`, `h` — size of the visible window
    # - `scroll_x`, `scroll_y` — offset into the source
    def blit(source : Canvas, *, x : Int, y : Int, w : Int, h : Int,
             scroll_x : Int = 0, scroll_y : Int = 0) : Nil
      sx = scroll_x.to_i
      sy = scroll_y.to_i
      bw = w.to_i
      bh = h.to_i
      tx = x.to_i
      ty = y.to_i

      bh.times do |row|
        src_y = sy + row
        next if src_y < 0 || src_y >= source.height

        col = 0
        while col < bw
          src_x = sx + col
          if src_x < 0 || src_x >= source.width
            col += 1
            next
          end

          c = source.cell(src_x, src_y)
          unless c.continuation?
            put(tx + col, ty + row, c.grapheme, c.style)
          end
          col += 1
        end
      end
    end
  end
end
