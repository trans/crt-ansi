module CRT::Ansi
  struct Panel
    @render : Renderer
    @x : Int32
    @y : Int32
    @h : Int32
    @v : Int32

    @border : Border? = nil
    @border_style : Style = Style.default

    @fill : Style | Style::Char | Nil = nil

    @text_content : String | Style::Text | Nil = nil
    @text_style : Style = Style.default
    @text_align : Align = Align::Left
    @text_valign : VAlign = VAlign::Top
    @text_wrap : Wrap = Wrap::None
    @text_pad : Int32 = 0
    @text_ellipsis : String? = nil

    @shadow : Bool = false
    @shadow_style : Style = Style.new(bg: Color.indexed(0))

    def initialize(@render : Renderer, @x : Int32, @y : Int32, *, @h : Int32, @v : Int32)
    end

    def border(border : Border = Border::Single, style : Style = Style.default) : self
      @border = border
      @border_style = style
      self
    end

    def fill(fill : Style | Style::Char) : self
      @fill = fill
      self
    end

    def text(content : String | Style::Text, *,
             style : Style = Style.default,
             align : Align = Align::Left,
             valign : VAlign = VAlign::Top,
             wrap : Wrap = Wrap::None,
             pad : Int32 = 0,
             ellipsis : String? = nil) : self
      @text_content = content
      @text_style = style
      @text_align = align
      @text_valign = valign
      @text_wrap = wrap
      @text_pad = pad
      @text_ellipsis = ellipsis
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
      draw_text if @text_content
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
                              in Style::Char then {f.char, f.style}
                              in Nil       then return
                              end

      ih.times do |j|
        iw.times do |i|
          @render.put(ix + i, iy + j, fill_char, fill_style)
        end
      end
    end

    private def draw_text : Nil
      content = @text_content
      return unless content

      inset = @border ? 1 : 0
      pad = @text_pad
      ix = @x + inset + pad
      iy = @y + inset
      iw = @h - (inset + pad) * 2
      ih = @v - inset * 2
      return if iw <= 0 || ih <= 0

      # Convert to styled spans if plain string.
      styled = case content
               in String     then Style::Text.new.add(content, @text_style)
               in Style::Text then content
               in Nil        then return
               end

      # Split into lines based on wrap mode.
      lines = layout_lines(styled, iw)

      # Apply vertical alignment / clipping.
      visible = select_visible_lines(lines, ih)

      visible.each_with_index do |line, row|
        write_aligned_spans(ix, iy + row, line, iw)
      end
    end

    # A single laid-out line: array of spans with their measured total width.
    private record LayoutLine, spans : Array(Style::Text::Span), width : Int32

    # Split styled text into layout lines based on wrap mode.
    private def layout_lines(text : Style::Text, width : Int32) : Array(LayoutLine)
      # First split on explicit newlines into segments.
      segments = split_on_newlines(text)

      lines = [] of LayoutLine
      segments.each do |segment|
        case @text_wrap
        in .none?
          lines << measure_line(segment)
        in .word?
          wrap_word(segment, width, lines)
        in .char?
          wrap_char(segment, width, lines)
        end
      end
      lines
    end

    # Split styled text on \n boundaries, producing an array of StyledText segments.
    private def split_on_newlines(text : Style::Text) : Array(Style::Text)
      segments = [Style::Text.new]

      text.spans.each do |span|
        parts = span.text.split('\n', remove_empty: false)
        parts.each_with_index do |part, i|
          segments << Style::Text.new if i > 0
          segments.last.add(part, span.style) unless part.empty?
        end
      end

      segments
    end

    private def measure_line(text : Style::Text) : LayoutLine
      w = 0
      text.each_grapheme { |_, gw, _| w += gw }
      LayoutLine.new(text.spans, w)
    end

    # Word wrap a single paragraph (no newlines) into lines.
    private def wrap_word(text : Style::Text, width : Int32, lines : Array(LayoutLine)) : Nil
      plain = text.to_s
      if plain.empty?
        lines << LayoutLine.new([] of Style::Text::Span, 0)
        return
      end

      # Build a flat list of graphemes with their styles for re-assembly.
      graphemes = [] of {String, Int32, Style}
      text.each_grapheme { |g, gw, s| graphemes << {g, gw, s} }

      # Word-wrap on the plain text, then map back to styled spans.
      words = split_into_words(graphemes)
      line_words = [] of Array({String, Int32, Style})
      line_len = 0

      words.each do |word|
        word_len = word.sum { |_, gw, _| gw }

        if word_len > width
          flush_word_line(line_words, line_len, lines) if line_len > 0
          break_long_graphemes(word, width, lines)
          line_words = [] of Array({String, Int32, Style})
          line_len = 0
          next
        end

        if line_len == 0
          line_words << word
          line_len = word_len
        elsif line_len + 1 + word_len <= width
          # Add space between words — use style of first grapheme of current word
          space_style = word.first[2]
          line_words << [{ " ", 1, space_style }]
          line_words << word
          line_len += 1 + word_len
        else
          flush_word_line(line_words, line_len, lines)
          line_words = [word]
          line_len = word_len
        end
      end

      flush_word_line(line_words, line_len, lines) if line_len > 0
    end

    # Split graphemes into words (splitting on whitespace graphemes).
    private def split_into_words(graphemes : Array({String, Int32, Style})) : Array(Array({String, Int32, Style}))
      words = [] of Array({String, Int32, Style})
      current = [] of {String, Int32, Style}

      graphemes.each do |g, gw, s|
        if g =~ /\s/
          words << current unless current.empty?
          current = [] of {String, Int32, Style}
        else
          current << {g, gw, s}
        end
      end

      words << current unless current.empty?
      words
    end

    private def flush_word_line(word_groups : Array(Array({String, Int32, Style})), len : Int32, lines : Array(LayoutLine)) : Nil
      return if len == 0
      spans = graphemes_to_spans(word_groups.flatten)
      lines << LayoutLine.new(spans, len)
    end

    private def break_long_graphemes(graphemes : Array({String, Int32, Style}), width : Int32, lines : Array(LayoutLine)) : Nil
      current = [] of {String, Int32, Style}
      current_len = 0

      graphemes.each do |g, gw, s|
        if current_len + gw > width && current_len > 0
          spans = graphemes_to_spans(current)
          lines << LayoutLine.new(spans, current_len)
          current = [] of {String, Int32, Style}
          current_len = 0
        end
        current << {g, gw, s}
        current_len += gw
      end

      if current_len > 0
        spans = graphemes_to_spans(current)
        lines << LayoutLine.new(spans, current_len)
      end
    end

    # Character wrap a single paragraph into lines.
    private def wrap_char(text : Style::Text, width : Int32, lines : Array(LayoutLine)) : Nil
      plain = text.to_s
      if plain.empty?
        lines << LayoutLine.new([] of Style::Text::Span, 0)
        return
      end

      current = [] of {String, Int32, Style}
      current_len = 0

      text.each_grapheme do |g, gw, s|
        if current_len + gw > width && current_len > 0
          spans = graphemes_to_spans(current)
          lines << LayoutLine.new(spans, current_len)
          current = [] of {String, Int32, Style}
          current_len = 0
        end
        current << {g, gw, s}
        current_len += gw
      end

      if current_len > 0
        spans = graphemes_to_spans(current)
        lines << LayoutLine.new(spans, current_len)
      end
    end

    # Convert a flat list of graphemes back into coalesced spans.
    private def graphemes_to_spans(graphemes : Array({String, Int32, Style})) : Array(Style::Text::Span)
      return [] of Style::Text::Span if graphemes.empty?

      spans = [] of Style::Text::Span
      current_text = String::Builder.new
      current_style = graphemes.first[2]

      graphemes.each do |g, _, s|
        if s == current_style
          current_text << g
        else
          spans << Style::Text::Span.new(current_text.to_s, current_style)
          current_text = String::Builder.new
          current_text << g
          current_style = s
        end
      end

      text = current_text.to_s
      spans << Style::Text::Span.new(text, current_style) unless text.empty?
      spans
    end

    # Select which lines are visible based on vertical alignment and available height.
    private def select_visible_lines(lines : Array(LayoutLine), max_lines : Int32) : Array(LayoutLine)
      return lines if lines.size <= max_lines

      case @text_valign
      in .top?
        lines[0, max_lines]
      in .bottom?
        lines[lines.size - max_lines, max_lines]
      in .middle?
        skip = (lines.size - max_lines) // 2
        lines[skip, max_lines]
      end
    end

    # Write a line of styled spans with horizontal alignment and clipping.
    private def write_aligned_spans(x : Int32, y : Int32, line : LayoutLine, width : Int32) : Nil
      spans = line.spans
      line_width = line.width

      if line_width <= width
        # Fits — just align within the space.
        offset = case @text_align
                 in .left?   then 0
                 in .center? then (width - line_width) // 2
                 in .right?  then width - line_width
                 end
        write_spans(x + offset, y, spans)
      else
        # Overflows — clip based on alignment.
        clip_and_write_spans(x, y, spans, line_width, width)
      end
    end

    # Write spans directly to the renderer (no clipping needed).
    private def write_spans(x : Int32, y : Int32, spans : Array(Style::Text::Span)) : Nil
      cx = x
      spans.each do |span|
        cx = @render.write(cx, y, span.text, span.style)
      end
    end

    # Clip overflowing spans based on alignment and optional ellipsis.
    private def clip_and_write_spans(x : Int32, y : Int32, spans : Array(Style::Text::Span),
                                     line_width : Int32, width : Int32) : Nil
      ellipsis = @text_ellipsis
      ellipsis_width = ellipsis ? DisplayWidth.width(ellipsis) : 0

      case @text_align
      in .left?
        clip_from_right(x, y, spans, width, ellipsis, ellipsis_width)
      in .right?
        clip_from_left(x, y, spans, line_width, width, ellipsis, ellipsis_width)
      in .center?
        clip_center(x, y, spans, line_width, width)
      end
    end

    # Left-aligned: keep beginning, clip end.
    private def clip_from_right(x : Int32, y : Int32, spans : Array(Style::Text::Span),
                                width : Int32, ellipsis : String?, ellipsis_width : Int32) : Nil
      avail = ellipsis ? width - ellipsis_width : width
      cx = x
      used = 0
      last_style = Style.default

      spans.each do |span|
        Graphemes.each(span.text) do |grapheme|
          gw = DisplayWidth.of(grapheme)
          break if used + gw > avail
          @render.put(cx, y, grapheme, span.style)
          cx += gw
          used += gw
          last_style = span.style
        end
        break if used >= avail
      end

      if ellipsis && used < width
        @render.write(cx, y, ellipsis, last_style)
      end
    end

    # Right-aligned: keep end, clip beginning.
    private def clip_from_left(x : Int32, y : Int32, spans : Array(Style::Text::Span),
                               line_width : Int32, width : Int32, ellipsis : String?,
                               ellipsis_width : Int32) : Nil
      avail = ellipsis ? width - ellipsis_width : width
      skip = line_width - avail

      # Write ellipsis at the start.
      cx = x
      if ellipsis
        first_style = spans.first?.try(&.style) || Style.default
        cx += @render.write(cx, y, ellipsis, first_style)
      end

      # Skip `skip` display-width units, then write the rest.
      skipped = 0
      spans.each do |span|
        Graphemes.each(span.text) do |grapheme|
          gw = DisplayWidth.of(grapheme)
          if skipped < skip
            skipped += gw
            next
          end
          break if cx - x >= width
          @render.put(cx, y, grapheme, span.style)
          cx += gw
        end
      end
    end

    # Center-aligned: clip both sides equally.
    private def clip_center(x : Int32, y : Int32, spans : Array(Style::Text::Span),
                            line_width : Int32, width : Int32) : Nil
      skip = (line_width - width) // 2

      cx = x
      skipped = 0
      written = 0
      spans.each do |span|
        Graphemes.each(span.text) do |grapheme|
          gw = DisplayWidth.of(grapheme)
          if skipped < skip
            skipped += gw
            next
          end
          break if written + gw > width
          @render.put(cx, y, grapheme, span.style)
          cx += gw
          written += gw
        end
      end
    end

    private def draw_shadow : Nil
      # Shadow: 1 cell right and 1 cell below the box
      (@v - 1).times do |j|
        @render.put(@x + @h, @y + 1 + j, " ", @shadow_style)
      end
      @h.times do |i|
        @render.put(@x + 1 + i, @y + @v, " ", @shadow_style)
      end
    end
  end
end
