module CRT::Ansi
  class EditLine
    getter text : String
    getter cursor : Int32
    getter scroll : Int32

    def initialize(@text : String = "")
      @cursor = 0
      @scroll = 0
    end

    def text=(value : String) : Nil
      @text = value
      count = grapheme_count
      @cursor = count if @cursor > count
    end

    def cursor=(pos : Int32) : Nil
      @cursor = pos.clamp(0, grapheme_count)
    end

    def grapheme_count : Int32
      Graphemes.count(@text)
    end

    def display_width : Int32
      DisplayWidth.width(@text)
    end

    def cursor_column : Int32
      DisplayWidth.width_to(@text, @cursor)
    end

    # Editing

    def insert(char : String) : Nil
      gs = Graphemes.to_a(@text)
      gs.insert(@cursor, char)
      @text = gs.join
      @cursor += 1
    end

    def delete_before : Nil
      return if @cursor == 0
      gs = Graphemes.to_a(@text)
      gs.delete_at(@cursor - 1)
      @text = gs.join
      @cursor -= 1
    end

    def delete_at : Nil
      gs = Graphemes.to_a(@text)
      return if @cursor >= gs.size
      gs.delete_at(@cursor)
      @text = gs.join
    end

    # Cursor movement

    def move_left : Nil
      @cursor -= 1 if @cursor > 0
    end

    def move_right : Nil
      @cursor += 1 if @cursor < grapheme_count
    end

    def move_home : Nil
      @cursor = 0
    end

    def move_end : Nil
      @cursor = grapheme_count
    end

    def move_to_column(col : Int32) : Nil
      @cursor = DisplayWidth.grapheme_at_column(@text, col)
    end

    # Rendering

    def render(canvas : Canvas, x : Int32, y : Int32, width : Int32,
               style : Style, cursor_style : Style? = nil) : Nil
      return if width <= 0
      ensure_cursor_visible(width)

      col = 0
      gi = 0
      Graphemes.each(@text) do |grapheme|
        gw = DisplayWidth.of(grapheme)
        dcol = col - @scroll

        if dcol >= 0 && dcol + gw <= width
          s = (gi == @cursor && cursor_style) ? style.merge(cursor_style) : style
          canvas.put(x + dcol, y, grapheme, s)
        end

        col += gw
        gi += 1
      end

      # Block cursor at end of text
      if gi == @cursor && cursor_style
        dcol = col - @scroll
        if dcol >= 0 && dcol < width
          canvas.put(x + dcol, y, " ", style.merge(cursor_style))
        end
      end
    end

    private def ensure_cursor_visible(width : Int32) : Nil
      cc = cursor_column
      if cc < @scroll
        @scroll = cc
      end
      if cc - @scroll >= width
        @scroll = cc - width + 1
      end
    end
  end
end
