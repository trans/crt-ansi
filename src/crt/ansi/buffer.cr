module CRT::Ansi
  class Buffer
    getter width : Int32
    getter height : Int32
    getter default_style : Style
    getter context : Context
    protected getter cells : Array(Cell)

    def initialize(width : Int, height : Int, *, style : Style = Style.default, context : Context = CRT::Ansi.context)
      @width = width.to_i
      @height = height.to_i
      @default_style = style
      @context = context

      raise ArgumentError.new("width must be positive") unless @width.positive?
      raise ArgumentError.new("height must be positive") unless @height.positive?

      @cells = Array(Cell).new(@width * @height) { Cell.blank(@default_style) }
    end

    def clear(style : Style = @default_style) : Nil
      blank = Cell.blank(style)
      @cells.fill(blank)
    end

    def put(x : Int, y : Int, grapheme : String, style : Style = @default_style) : Nil
      x_i = x.to_i
      y_i = y.to_i
      return unless in_bounds?(x_i, y_i)

      cluster = first_grapheme(grapheme)
      cluster = @context.grapheme_filter.call(cluster)
      cluster = sanitize_cluster(cluster)
      width = @context.width_resolver.call(cluster)
      width = width >= 2 ? 2 : 1
      width = 1 if width == 2 && x_i == @width - 1

      place(x_i, y_i, cluster, style, width)
    end

    def write(x : Int, y : Int, text : String, style : Style = @default_style) : Int32
      x_i = x.to_i
      y_i = y.to_i
      return x_i unless row_in_bounds?(y_i)

      cursor_x = x_i
      Graphemes.each(text) do |cluster|
        break if cursor_x >= @width

        case cluster
        when "\n", "\r"
          break
        when "\t"
          tab_size = 4 - (cursor_x % 4)
          tab_size.times do
            break if cursor_x >= @width
            place(cursor_x, y_i, " ", style, 1)
            cursor_x += 1
          end
        else
          cluster = @context.grapheme_filter.call(cluster)
          cluster = sanitize_cluster(cluster)
          width = @context.width_resolver.call(cluster)
          next if width <= 0

          width = width >= 2 ? 2 : 1
          width = 1 if width == 2 && cursor_x == @width - 1

          place(cursor_x, y_i, cluster, style, width)
          cursor_x += width
        end
      end

      cursor_x
    end

    def cell(x : Int, y : Int) : Cell
      x_i = x.to_i
      y_i = y.to_i
      raise IndexError.new unless in_bounds?(x_i, y_i)

      @cells[index(x_i, y_i)]
    end

    def copy_from(other : Buffer) : Nil
      unless @width == other.width && @height == other.height
        raise ArgumentError.new("buffer dimensions must match")
      end

      source = other.cells
      @cells.size.times do |idx|
        @cells[idx] = source[idx]
      end
    end

    def ==(other : Buffer) : Bool
      @width == other.width && @height == other.height && @cells == other.cells
    end

    private def place(x : Int32, y : Int32, grapheme : String, style : Style, width : Int32) : Nil
      return unless in_bounds?(x, y)

      detach_cell(x, y)
      if width == 2
        return if x + 1 >= @width
        detach_cell(x + 1, y)
      end

      @cells[index(x, y)] = Cell.new(grapheme: grapheme, style: style, width: width, continuation: false)

      if width == 2
        @cells[index(x + 1, y)] = Cell.continuation(style)
      end
    end

    private def detach_cell(x : Int32, y : Int32) : Nil
      return unless in_bounds?(x, y)

      idx = index(x, y)
      cell = @cells[idx]

      if cell.continuation?
        if x > 0
          prev_idx = index(x - 1, y)
          prev_cell = @cells[prev_idx]
          @cells[prev_idx] = Cell.blank(prev_cell.style) if prev_cell.width == 2
        end
      elsif cell.width == 2
        if x + 1 < @width
          @cells[index(x + 1, y)] = Cell.blank(cell.style)
        end
      end

      @cells[idx] = Cell.blank(cell.style)
    end

    private def first_grapheme(text : String) : String
      return " " if text.empty?

      value = " "
      Graphemes.each(text) do |cluster|
        value = cluster
        break
      end
      value
    end

    private def sanitize_cluster(cluster : String) : String
      cluster.each_char do |char|
        ord = char.ord
        if (0x00..0x1F).includes?(ord) || (0x7F..0x9F).includes?(ord)
          return " "
        end
      end

      cluster
    end

    private def index(x : Int32, y : Int32) : Int32
      y * @width + x
    end

    private def in_bounds?(x : Int32, y : Int32) : Bool
      row_in_bounds?(y) && x >= 0 && x < @width
    end

    private def row_in_bounds?(y : Int32) : Bool
      y >= 0 && y < @height
    end
  end
end
