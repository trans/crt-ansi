module CRT::Ansi
  class Boxing
    @[Flags]
    enum Edge
      Up
      Down
      Left
      Right
    end

    record Op, x : Int32, y : Int32, w : Int32, h : Int32

    @grid : Array(Array(Edge))
    @ops : Array(Op)
    @border : Border
    property style : Style = Style.default

    def initialize(*, @border : Border = Border::Single,
                   width : Int32 = 0, height : Int32 = 0)
      @grid = Array.new(height) { Array.new(width, Edge::None) }
      @ops = [] of Op
    end

    getter border : Border

    def width : Int32
      @grid.empty? ? 0 : @grid[0].size
    end

    def height : Int32
      @grid.size
    end

    def add(*, x : Int32, y : Int32, w : Int32, h : Int32) : self
      op = Op.new(x: x, y: y, w: w, h: h)
      @ops << op
      ensure_size(x + w, y + h)
      apply_op(op)
      self
    end

    def remove(*, x : Int32, y : Int32, w : Int32, h : Int32) : self
      target = Op.new(x: x, y: y, w: w, h: h)
      @ops.delete(target)
      rebuild_grid
      self
    end

    def edges_at(x : Int32, y : Int32) : Edge
      if x >= 0 && x < width && y >= 0 && y < height
        @grid[y][x]
      else
        Edge::None
      end
    end

    def clear : Nil
      @ops.clear
      @grid.each { |row| row.fill(Edge::None) }
    end

    def resize(w : Int32, h : Int32) : Nil
      @grid = Array.new(h) { Array.new(w, Edge::None) }
      @ops.each { |op| apply_op(op) }
    end

    def draw(canvas : Canvas) : Nil
      draw(canvas, @style)
    end

    def draw(canvas : Canvas, style : Style) : Nil
      height.times do |y|
        width.times do |x|
          edge = @grid[y][x]
          next if edge.none?
          ch = edge_char(edge)
          canvas.put(x, y, ch, style) unless ch == " "
        end
      end
    end

    # --- Private ---

    private def ensure_size(need_w : Int32, need_h : Int32) : Nil
      cur_w = width
      cur_h = height

      return if need_w <= cur_w && need_h <= cur_h

      new_w = {cur_w, need_w}.max
      new_h = {cur_h, need_h}.max

      if new_h > cur_h || new_w > cur_w
        @grid = Array.new(new_h) do |row|
          if row < cur_h
            old_row = @grid[row]
            if new_w > cur_w
              old_row + Array.new(new_w - cur_w, Edge::None)
            else
              old_row
            end
          else
            Array.new(new_w, Edge::None)
          end
        end
      end
    end

    private def apply_op(op : Op) : Nil
      apply_box(op.x, op.y, op.w, op.h)
    end

    private def apply_box(x : Int32, y : Int32, w : Int32, h : Int32) : Nil
      apply_hline(x, y, w)
      apply_hline(x, y + h - 1, w)
      apply_vline(x, y, h)
      apply_vline(x + w - 1, y, h)
    end

    private def apply_hline(x : Int32, y : Int32, length : Int32) : Nil
      x_start = x.clamp(0, width - 1)
      x_end = (x + length - 1).clamp(0, width - 1)
      return if x_start > x_end || y < 0 || y >= height

      (x_start..x_end).each do |cx|
        edges = Edge::None
        edges |= Edge::Right if cx < x_end
        edges |= Edge::Left if cx > x_start
        @grid[y][cx] |= edges
      end
    end

    private def apply_vline(x : Int32, y : Int32, length : Int32) : Nil
      y_start = y.clamp(0, height - 1)
      y_end = (y + length - 1).clamp(0, height - 1)
      return if y_start > y_end || x < 0 || x >= width

      (y_start..y_end).each do |cy|
        edges = Edge::None
        edges |= Edge::Down if cy < y_end
        edges |= Edge::Up if cy > y_start
        @grid[cy][x] |= edges
      end
    end

    private def rebuild_grid : Nil
      @grid.each { |row| row.fill(Edge::None) }
      @ops.each { |op| apply_op(op) }
    end

    private def edge_char(edge : Edge) : String
      case @border
      in .single?
        single_char(edge)
      in .rounded?
        case edge
        when Edge::Right | Edge::Down then "╭"
        when Edge::Left | Edge::Down  then "╮"
        when Edge::Right | Edge::Up   then "╰"
        when Edge::Left | Edge::Up    then "╯"
        else                               single_char(edge)
        end
      in .double?
        double_char(edge)
      in .heavy?
        heavy_char(edge)
      in .ascii?
        ascii_char(edge)
      in .none?
        " "
      end
    end

    private def single_char(edge : Edge) : String
      l, r, u, d = edge.left?, edge.right?, edge.up?, edge.down?
      return "┼" if l && r && u && d
      return "├" if u && d && r
      return "┤" if u && d && l
      return "┬" if l && r && d
      return "┴" if l && r && u
      return "┌" if r && d
      return "┐" if l && d
      return "└" if r && u
      return "┘" if l && u
      return "─" if l || r
      return "│" if u || d
      " "
    end

    private def double_char(edge : Edge) : String
      l, r, u, d = edge.left?, edge.right?, edge.up?, edge.down?
      return "╬" if l && r && u && d
      return "╠" if u && d && r
      return "╣" if u && d && l
      return "╦" if l && r && d
      return "╩" if l && r && u
      return "╔" if r && d
      return "╗" if l && d
      return "╚" if r && u
      return "╝" if l && u
      return "═" if l || r
      return "║" if u || d
      " "
    end

    private def heavy_char(edge : Edge) : String
      l, r, u, d = edge.left?, edge.right?, edge.up?, edge.down?
      return "╋" if l && r && u && d
      return "┣" if u && d && r
      return "┫" if u && d && l
      return "┳" if l && r && d
      return "┻" if l && r && u
      return "┏" if r && d
      return "┓" if l && d
      return "┗" if r && u
      return "┛" if l && u
      return "━" if l || r
      return "┃" if u || d
      " "
    end

    private def ascii_char(edge : Edge) : String
      l, r, u, d = edge.left?, edge.right?, edge.up?, edge.down?
      return "+" if (l || r) && (u || d)
      return "-" if l || r
      return "|" if u || d
      " "
    end
  end
end
