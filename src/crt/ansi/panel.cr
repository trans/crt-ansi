module CRT::Ansi
  struct Panel
    @render : Renderer
    @x : Int32
    @y : Int32
    @h : Int32
    @v : Int32

    @border : Border? = nil
    @border_style : Style = Style.default

    @fill : Style | StyleChar | Nil = nil

    @text : String? = nil
    @text_style : Style = Style.default
    @text_align : Align = Align::Left
    @text_wrap : Bool = false
    @text_pad : Int32 = 0

    @shadow : Bool = false
    @shadow_style : Style = Style.new(bg: Color.indexed(0))

    def initialize(@render : Renderer, @x : Int32, @y : Int32, *, @h : Int32, @v : Int32)
    end

    def border(border : Border = Border::Single, style : Style = Style.default) : self
      @border = border
      @border_style = style
      self
    end

    def fill(fill : Style | StyleChar) : self
      @fill = fill
      self
    end

    def text(content : String, *,
             style : Style = Style.default,
             align : Align = Align::Left,
             wrap : Bool = false,
             pad : Int32 = 0) : self
      @text = content
      @text_style = style
      @text_align = align
      @text_wrap = wrap
      @text_pad = pad
      self
    end

    def shadow(style : Style = Style.new(bg: Color.indexed(0))) : self
      @shadow = true
      @shadow_style = style
      self
    end

    def draw : Nil
      draw_shadow if @shadow
      draw_fill if @fill
      draw_border if @border
      draw_text if @text
    end

    # --- Private drawing methods ---

    private def draw_border : Nil
      b = @border
      return unless b
      @render.box(@x, @y, h: @h, v: @v, border: b, style: @border_style)
    end

    private def draw_fill : Nil
      f = @fill
      return unless f
      inset = @border ? 1 : 0
      ix = @x + inset
      iy = @y + inset
      iw = @h - inset * 2
      ih = @v - inset * 2
      return if iw <= 0 || ih <= 0

      fill_char, fill_style = case f
                              in Style     then {" ", f}
                              in StyleChar then {f.char, f.style}
                              in Nil       then return
                              end

      ih.times do |j|
        iw.times do |i|
          @render.put(ix + i, iy + j, fill_char, fill_style)
        end
      end
    end

    private def draw_text : Nil
      content = @text
      return unless content

      inset = @border ? 1 : 0
      pad = @text_pad
      ix = @x + inset + pad
      iy = @y + inset
      iw = @h - (inset + pad) * 2
      ih = @v - inset * 2
      return if iw <= 0 || ih <= 0

      lines = @text_wrap ? word_wrap(content, iw) : [content]

      lines.each_with_index do |line, row|
        break if row >= ih
        write_aligned(ix, iy + row, line, iw)
      end
    end

    private def write_aligned(x : Int32, y : Int32, line : String, width : Int32) : Nil
      # Truncate if needed
      display_len = 0
      truncated = String::Builder.new
      Graphemes.each(line) do |grapheme|
        gw = DisplayWidth.of(grapheme)
        break if display_len + gw > width
        truncated << grapheme
        display_len += gw
      end
      text = truncated.to_s

      case @text_align
      in .left?
        @render.write(x, y, text, @text_style)
      in .center?
        offset = (width - display_len) // 2
        @render.write(x + offset, y, text, @text_style)
      in .right?
        offset = width - display_len
        @render.write(x + offset, y, text, @text_style)
      end
    end

    private def word_wrap(text : String, width : Int32) : Array(String)
      lines = [] of String
      text.split('\n').each do |paragraph|
        wrap_paragraph(paragraph, width, lines)
      end
      lines
    end

    private def wrap_paragraph(paragraph : String, width : Int32, lines : Array(String)) : Nil
      if paragraph.empty?
        lines << ""
        return
      end

      words = paragraph.split(/\s+/)
      line = String::Builder.new
      line_len = 0

      words.each do |word|
        word_len = DisplayWidth.width(word)

        if word_len > width
          # Word too long for a line — break it character by character
          flush_line(line, line_len, lines) if line_len > 0
          break_long_word(word, width, lines)
          line = String::Builder.new
          line_len = 0
          next
        end

        if line_len == 0
          line << word
          line_len = word_len
        elsif line_len + 1 + word_len <= width
          line << ' ' << word
          line_len += 1 + word_len
        else
          lines << line.to_s
          line = String::Builder.new
          line << word
          line_len = word_len
        end
      end

      lines << line.to_s if line_len > 0
    end

    private def flush_line(builder : String::Builder, len : Int32, lines : Array(String)) : Nil
      lines << builder.to_s if len > 0
    end

    private def break_long_word(word : String, width : Int32, lines : Array(String)) : Nil
      line = String::Builder.new
      line_len = 0

      Graphemes.each(word) do |grapheme|
        gw = DisplayWidth.of(grapheme)
        if line_len + gw > width && line_len > 0
          lines << line.to_s
          line = String::Builder.new
          line_len = 0
        end
        line << grapheme
        line_len += gw
      end

      lines << line.to_s if line_len > 0
    end

    private def draw_shadow : Nil
      # Shadow: 1 cell right and 1 cell below the box
      # Right edge shadow (1 column wide, full height minus top row)
      (@v - 1).times do |j|
        @render.put(@x + @h, @y + 1 + j, " ", @shadow_style)
      end
      # Bottom edge shadow (full width minus left column, plus corner)
      @h.times do |i|
        @render.put(@x + 1 + i, @y + @v, " ", @shadow_style)
      end
    end
  end
end
