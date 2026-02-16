require "../../spec_helper"

alias BoxingEdge = CRT::Ansi::Boxing::Edge

describe CRT::Ansi::Boxing do

  describe "construction" do
    it "creates with default size" do
      b = CRT::Ansi::Boxing.new
      b.width.should eq(0)
      b.height.should eq(0)
      b.border.should eq(CRT::Ansi::Border::Single)
    end

    it "creates with explicit size" do
      b = CRT::Ansi::Boxing.new(width: 20, height: 10)
      b.width.should eq(20)
      b.height.should eq(10)
    end

    it "accepts border style" do
      b = CRT::Ansi::Boxing.new(border: CRT::Ansi::Border::Double)
      b.border.should eq(CRT::Ansi::Border::Double)
    end
  end

  describe "#add" do
    it "auto-grows grid to fit" do
      b = CRT::Ansi::Boxing.new
      b.add(x: 0, y: 0, w: 5, h: 3)
      b.width.should eq(5)
      b.height.should eq(3)
    end

    it "sets corner edges" do
      b = CRT::Ansi::Boxing.new
      b.add(x: 0, y: 0, w: 5, h: 3)
      # Top-left: right + down
      b.edges_at(0, 0).should eq(BoxingEdge::Right | BoxingEdge::Down)
      # Top-right: left + down
      b.edges_at(4, 0).should eq(BoxingEdge::Left | BoxingEdge::Down)
      # Bottom-left: right + up
      b.edges_at(0, 2).should eq(BoxingEdge::Right | BoxingEdge::Up)
      # Bottom-right: left + up
      b.edges_at(4, 2).should eq(BoxingEdge::Left | BoxingEdge::Up)
    end

    it "sets horizontal edge flags" do
      b = CRT::Ansi::Boxing.new
      b.add(x: 0, y: 0, w: 5, h: 3)
      # Top edge middle cells: left + right
      b.edges_at(2, 0).should eq(BoxingEdge::Left | BoxingEdge::Right)
      # Bottom edge middle cells
      b.edges_at(2, 2).should eq(BoxingEdge::Left | BoxingEdge::Right)
    end

    it "sets vertical edge flags" do
      b = CRT::Ansi::Boxing.new
      b.add(x: 0, y: 0, w: 5, h: 4)
      # Left edge middle cells: up + down
      b.edges_at(0, 1).should eq(BoxingEdge::Up | BoxingEdge::Down)
      b.edges_at(0, 2).should eq(BoxingEdge::Up | BoxingEdge::Down)
      # Right edge middle cells
      b.edges_at(4, 1).should eq(BoxingEdge::Up | BoxingEdge::Down)
    end

    it "interior cells have no edges" do
      b = CRT::Ansi::Boxing.new
      b.add(x: 0, y: 0, w: 5, h: 4)
      b.edges_at(2, 1).should eq(BoxingEdge::None)
      b.edges_at(2, 2).should eq(BoxingEdge::None)
    end

    it "chains" do
      b = CRT::Ansi::Boxing.new
      result = b.add(x: 0, y: 0, w: 3, h: 3)
      result.should be(b)
    end
  end

  describe "adjacent boxes" do
    it "creates T-junctions on shared edge" do
      b = CRT::Ansi::Boxing.new
      # Two boxes side by side sharing x=5 edge
      b.add(x: 0, y: 0, w: 6, h: 3)
      b.add(x: 5, y: 0, w: 6, h: 3)
      # Shared corners become T-junctions
      # Top shared: left + right + down
      b.edges_at(5, 0).should eq(BoxingEdge::Left | BoxingEdge::Right | BoxingEdge::Down)
      # Bottom shared: left + right + up
      b.edges_at(5, 2).should eq(BoxingEdge::Left | BoxingEdge::Right | BoxingEdge::Up)
      # Shared vertical middle: up + down + left + right (from both boxes)
      # Actually at x=5, y=1: left side's right edge (up+down) and right side's left edge (up+down)
      # The cell is both a left vertical and right vertical
      # From left box: x=5 is right edge → up+down
      # From right box: x=5 is left edge → up+down
      # Combined: up+down (same thing)
      b.edges_at(5, 1).should eq(BoxingEdge::Up | BoxingEdge::Down)
    end

    it "creates T-junctions on shared horizontal edge" do
      b = CRT::Ansi::Boxing.new
      # Two boxes stacked sharing y=3 edge
      b.add(x: 0, y: 0, w: 5, h: 4)
      b.add(x: 0, y: 3, w: 5, h: 4)
      # Left shared: right + up + down
      b.edges_at(0, 3).should eq(BoxingEdge::Right | BoxingEdge::Up | BoxingEdge::Down)
      # Right shared: left + up + down
      b.edges_at(4, 3).should eq(BoxingEdge::Left | BoxingEdge::Up | BoxingEdge::Down)
      # Middle of shared edge: left + right (same)
      b.edges_at(2, 3).should eq(BoxingEdge::Left | BoxingEdge::Right)
    end

    it "creates cross at intersection of two boxes" do
      b = CRT::Ansi::Boxing.new
      # A 2x2 grid of boxes
      b.add(x: 0, y: 0, w: 6, h: 4)
      b.add(x: 5, y: 0, w: 6, h: 4)
      b.add(x: 0, y: 3, w: 6, h: 4)
      b.add(x: 5, y: 3, w: 6, h: 4)
      # Center point: all four directions
      b.edges_at(5, 3).should eq(BoxingEdge::Up | BoxingEdge::Down | BoxingEdge::Left | BoxingEdge::Right)
    end
  end

  describe "#remove" do
    it "removes a box and rebuilds" do
      b = CRT::Ansi::Boxing.new
      b.add(x: 0, y: 0, w: 5, h: 3)
      b.add(x: 5, y: 0, w: 5, h: 3)
      b.remove(x: 5, y: 0, w: 5, h: 3)
      # Right edge of remaining box should be normal corner
      b.edges_at(4, 0).should eq(BoxingEdge::Left | BoxingEdge::Down)
      # Old second box area should be clear
      b.edges_at(6, 0).should eq(BoxingEdge::None)
    end
  end

  describe "#clear" do
    it "resets all edges" do
      b = CRT::Ansi::Boxing.new
      b.add(x: 0, y: 0, w: 5, h: 3)
      b.clear
      b.edges_at(0, 0).should eq(BoxingEdge::None)
      b.edges_at(2, 0).should eq(BoxingEdge::None)
    end
  end

  describe "#resize" do
    it "resizes grid and reapplies ops" do
      b = CRT::Ansi::Boxing.new(width: 10, height: 10)
      b.add(x: 0, y: 0, w: 5, h: 3)
      b.resize(20, 20)
      b.width.should eq(20)
      b.height.should eq(20)
      # Box should still be present
      b.edges_at(0, 0).should eq(BoxingEdge::Right | BoxingEdge::Down)
    end
  end

  describe "character mapping" do
    describe "Single border" do
      it "maps corners" do
        b = CRT::Ansi::Boxing.new(border: CRT::Ansi::Border::Single)
        b.add(x: 0, y: 0, w: 3, h: 3)

        io = IO::Memory.new
        render = CRT::Ansi::Render.new(io, 3, 3)
        b.draw(render)

        render.cell(0, 0).grapheme.should eq("┌")
        render.cell(2, 0).grapheme.should eq("┐")
        render.cell(0, 2).grapheme.should eq("└")
        render.cell(2, 2).grapheme.should eq("┘")
      end

      it "maps lines" do
        b = CRT::Ansi::Boxing.new(border: CRT::Ansi::Border::Single)
        b.add(x: 0, y: 0, w: 4, h: 3)

        io = IO::Memory.new
        render = CRT::Ansi::Render.new(io, 4, 3)
        b.draw(render)

        render.cell(1, 0).grapheme.should eq("─")
        render.cell(0, 1).grapheme.should eq("│")
      end

      it "maps T-junctions" do
        b = CRT::Ansi::Boxing.new(border: CRT::Ansi::Border::Single)
        b.add(x: 0, y: 0, w: 4, h: 3)
        b.add(x: 3, y: 0, w: 4, h: 3)

        io = IO::Memory.new
        render = CRT::Ansi::Render.new(io, 7, 3)
        b.draw(render)

        render.cell(3, 0).grapheme.should eq("┬")
        render.cell(3, 2).grapheme.should eq("┴")
      end

      it "maps cross" do
        b = CRT::Ansi::Boxing.new(border: CRT::Ansi::Border::Single)
        b.add(x: 0, y: 0, w: 4, h: 3)
        b.add(x: 3, y: 0, w: 4, h: 3)
        b.add(x: 0, y: 2, w: 4, h: 3)
        b.add(x: 3, y: 2, w: 4, h: 3)

        io = IO::Memory.new
        render = CRT::Ansi::Render.new(io, 7, 5)
        b.draw(render)

        render.cell(3, 2).grapheme.should eq("┼")
      end

      it "maps left and right tees" do
        b = CRT::Ansi::Boxing.new(border: CRT::Ansi::Border::Single)
        b.add(x: 0, y: 0, w: 4, h: 3)
        b.add(x: 0, y: 2, w: 4, h: 3)

        io = IO::Memory.new
        render = CRT::Ansi::Render.new(io, 4, 5)
        b.draw(render)

        render.cell(0, 2).grapheme.should eq("├")
        render.cell(3, 2).grapheme.should eq("┤")
      end
    end

    describe "Double border" do
      it "maps corners and lines" do
        b = CRT::Ansi::Boxing.new(border: CRT::Ansi::Border::Double)
        b.add(x: 0, y: 0, w: 3, h: 3)

        io = IO::Memory.new
        render = CRT::Ansi::Render.new(io, 3, 3)
        b.draw(render)

        render.cell(0, 0).grapheme.should eq("╔")
        render.cell(2, 0).grapheme.should eq("╗")
        render.cell(0, 2).grapheme.should eq("╚")
        render.cell(2, 2).grapheme.should eq("╝")
        render.cell(1, 0).grapheme.should eq("═")
        render.cell(0, 1).grapheme.should eq("║")
      end
    end

    describe "Heavy border" do
      it "maps corners and lines" do
        b = CRT::Ansi::Boxing.new(border: CRT::Ansi::Border::Heavy)
        b.add(x: 0, y: 0, w: 3, h: 3)

        io = IO::Memory.new
        render = CRT::Ansi::Render.new(io, 3, 3)
        b.draw(render)

        render.cell(0, 0).grapheme.should eq("┏")
        render.cell(2, 0).grapheme.should eq("┓")
        render.cell(0, 2).grapheme.should eq("┗")
        render.cell(2, 2).grapheme.should eq("┛")
        render.cell(1, 0).grapheme.should eq("━")
        render.cell(0, 1).grapheme.should eq("┃")
      end
    end

    describe "Rounded border" do
      it "uses rounded corners for simple box" do
        b = CRT::Ansi::Boxing.new(border: CRT::Ansi::Border::Rounded)
        b.add(x: 0, y: 0, w: 3, h: 3)

        io = IO::Memory.new
        render = CRT::Ansi::Render.new(io, 3, 3)
        b.draw(render)

        render.cell(0, 0).grapheme.should eq("╭")
        render.cell(2, 0).grapheme.should eq("╮")
        render.cell(0, 2).grapheme.should eq("╰")
        render.cell(2, 2).grapheme.should eq("╯")
        # Lines are still single-style
        render.cell(1, 0).grapheme.should eq("─")
      end

      it "falls back to single at intersections" do
        b = CRT::Ansi::Boxing.new(border: CRT::Ansi::Border::Rounded)
        b.add(x: 0, y: 0, w: 4, h: 3)
        b.add(x: 3, y: 0, w: 4, h: 3)

        io = IO::Memory.new
        render = CRT::Ansi::Render.new(io, 7, 3)
        b.draw(render)

        # T-junction uses Single glyph, not rounded
        render.cell(3, 0).grapheme.should eq("┬")
        render.cell(3, 2).grapheme.should eq("┴")
        # Non-intersected corners stay rounded
        render.cell(0, 0).grapheme.should eq("╭")
        render.cell(6, 0).grapheme.should eq("╮")
      end
    end

    describe "ASCII border" do
      it "maps corners as + and lines as - |" do
        b = CRT::Ansi::Boxing.new(border: CRT::Ansi::Border::ASCII)
        b.add(x: 0, y: 0, w: 3, h: 3)

        io = IO::Memory.new
        render = CRT::Ansi::Render.new(io, 3, 3)
        b.draw(render)

        render.cell(0, 0).grapheme.should eq("+")
        render.cell(1, 0).grapheme.should eq("-")
        render.cell(0, 1).grapheme.should eq("|")
      end
    end
  end

  describe "#draw" do
    it "applies style to cells" do
      b = CRT::Ansi::Boxing.new(border: CRT::Ansi::Border::Single)
      b.style = CRT::Ansi::Style.new(bold: true)
      b.add(x: 0, y: 0, w: 3, h: 3)

      io = IO::Memory.new
      render = CRT::Ansi::Render.new(io, 3, 3)
      b.draw(render)

      render.cell(0, 0).style.bold.should be_true
    end

    it "does not write to interior cells" do
      b = CRT::Ansi::Boxing.new(border: CRT::Ansi::Border::Single)
      b.add(x: 0, y: 0, w: 5, h: 5)

      io = IO::Memory.new
      render = CRT::Ansi::Render.new(io, 5, 5)
      b.draw(render)

      # Interior should remain default
      render.cell(2, 2).grapheme.should eq(" ")
    end
  end

  describe "bounds clamping" do
    it "auto-grows grid when box exceeds initial size" do
      b = CRT::Ansi::Boxing.new(width: 5, height: 5)
      b.add(x: 3, y: 3, w: 5, h: 5)
      # Grid grew to fit the full box
      b.width.should eq(8)
      b.height.should eq(8)
      b.edges_at(7, 3).should eq(BoxingEdge::Left | BoxingEdge::Down)
      b.edges_at(7, 7).should eq(BoxingEdge::Left | BoxingEdge::Up)
    end

    it "clamps ops to grid after resize-down" do
      b = CRT::Ansi::Boxing.new
      b.add(x: 3, y: 3, w: 5, h: 5)
      b.resize(5, 5)
      # Only the top-left corner of the box is visible
      b.edges_at(3, 3).should eq(BoxingEdge::Right | BoxingEdge::Down)
      # Clamped edges — only the direction toward the corner
      b.edges_at(4, 3).should eq(BoxingEdge::Left)
      b.edges_at(3, 4).should eq(BoxingEdge::Up)
      # Beyond the corner is empty
      b.edges_at(4, 4).should eq(BoxingEdge::None)
    end
  end
end
