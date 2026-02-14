module CRT::Ansi
  class Renderer
    getter front_buffer : Buffer
    getter back_buffer : Buffer
    getter origin_x : Int32
    getter origin_y : Int32
    getter context : Context

    def initialize(@io : IO, width : Int, height : Int, *, origin_x : Int = 1, origin_y : Int = 1, context : Context = CRT::Ansi.context)
      @origin_x = origin_x.to_i
      @origin_y = origin_y.to_i
      @context = context
      raise ArgumentError.new("origin_x must be >= 1") unless @origin_x >= 1
      raise ArgumentError.new("origin_y must be >= 1") unless @origin_y >= 1

      @front_buffer = Buffer.new(width, height, context: @context)
      @back_buffer = Buffer.new(width, height, context: @context)

      @needs_full_redraw = true
      @active_style = Style.default
      @cursor_x = -1
      @cursor_y = -1
    end

    def resize(width : Int, height : Int) : Nil
      @front_buffer = Buffer.new(width, height, context: @context)
      @back_buffer = Buffer.new(width, height, context: @context)
      @cursor_x = -1
      @cursor_y = -1
      @active_style = Style.default
      @needs_full_redraw = true
    end

    def force_full_redraw! : Nil
      @needs_full_redraw = true
      @cursor_x = -1
      @cursor_y = -1
    end

    def reset_terminal_state! : Nil
      output = String.build do |io|
        io << Hyperlink.close_sequence(@context.osc_terminator) if effective_hyperlink(@active_style)
        io << "\e[0m"
      end

      @io << output
      @io.flush

      @active_style = Style.default
      @cursor_x = -1
      @cursor_y = -1
      @needs_full_redraw = true
    end

    def present : Int32
      output = String.build do |io|
        if @needs_full_redraw
          render_full(io)
        else
          render_diff(io)
        end
      end

      unless output.empty?
        @io << output
        @io.flush
      end

      @front_buffer.copy_from(@back_buffer)
      @needs_full_redraw = false

      output.bytesize
    end

    private def render_full(io : IO) : Nil
      y = 0
      while y < @back_buffer.height
        render_span(io, y, 0, @back_buffer.width)
        y += 1
      end
    end

    private def render_diff(io : IO) : Nil
      y = 0
      while y < @back_buffer.height
        x = 0
        while x < @back_buffer.width
          if @back_buffer.cell(x, y) == @front_buffer.cell(x, y)
            x += 1
            next
          end

          start_x = x
          x += 1
          while x < @back_buffer.width && @back_buffer.cell(x, y) != @front_buffer.cell(x, y)
            x += 1
          end

          render_span(io, y, start_x, x)
        end
        y += 1
      end
    end

    private def render_span(io : IO, row : Int32, start_x : Int32, end_x : Int32) : Nil
      printed = false
      x = start_x
      while x < end_x
        cell = @back_buffer.cell(x, row)
        unless cell.continuation?
          unless printed
            move_cursor(io, x, row)
            printed = true
          end

          apply_style(io, cell.style)
          io << cell.grapheme
          @cursor_x += cell.width
        end
        x += 1
      end
    end

    private def move_cursor(io : IO, x : Int32, y : Int32) : Nil
      target_x = @origin_x + x
      target_y = @origin_y + y
      return if target_x == @cursor_x && target_y == @cursor_y

      io << "\e[" << target_y << ';' << target_x << 'H'
      @cursor_x = target_x
      @cursor_y = target_y
    end

    private def apply_style(io : IO, style : Style) : Nil
      return if style == @active_style

      capabilities = @context.capabilities
      old_link = effective_hyperlink(@active_style)
      new_link = effective_hyperlink(style)

      if old_link && old_link != new_link
        io << Hyperlink.close_sequence(@context.osc_terminator)
      end

      style.append_sgr(io, capabilities)

      if new_link && new_link != old_link
        io << new_link.open_sequence(@context.osc_terminator)
      end

      @active_style = style
    end

    private def effective_hyperlink(style : Style) : Hyperlink?
      @context.capabilities.hyperlinks ? style.hyperlink : nil
    end
  end
end
