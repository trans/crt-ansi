require "../../spec_helper"

private def render(w = 20, h = 10)
  CRT::Ansi::Render.new(IO::Memory.new, w, h)
end

describe CRT::Ansi::Viewport do
  describe "#put / #write / #cell" do
    it "stores and retrieves cells" do
      vp = CRT::Ansi::Viewport.new(width: 10, height: 5)
      vp.put(3, 2, "X")
      vp.cell(3, 2).grapheme.should eq("X")
    end

    it "writes a string and returns cursor position" do
      vp = CRT::Ansi::Viewport.new(width: 20, height: 5)
      cx = vp.write(0, 0, "Hello")
      cx.should eq(5)
      vp.cell(0, 0).grapheme.should eq("H")
      vp.cell(4, 0).grapheme.should eq("o")
    end
  end

  describe "#clear" do
    it "resets all cells" do
      vp = CRT::Ansi::Viewport.new(width: 5, height: 3)
      vp.write(0, 0, "Hello")
      vp.clear
      vp.cell(0, 0).blank?.should be_true
    end
  end

  describe "Canvas#blit" do
    it "copies visible window from viewport to render" do
      vp = CRT::Ansi::Viewport.new(width: 20, height: 20)
      vp.write(0, 0, "ABCDE")
      vp.write(0, 1, "FGHIJ")

      r = render(10, 5)
      r.blit(vp, x: 2, y: 1, w: 5, h: 2)

      r.cell(2, 1).grapheme.should eq("A")
      r.cell(6, 1).grapheme.should eq("E")
      r.cell(2, 2).grapheme.should eq("F")
      r.cell(6, 2).grapheme.should eq("J")
    end

    it "applies scroll_y offset" do
      vp = CRT::Ansi::Viewport.new(width: 10, height: 100)
      vp.write(0, 50, "Row50")
      vp.write(0, 51, "Row51")

      r = render(10, 5)
      r.blit(vp, x: 0, y: 0, w: 5, h: 2, scroll_y: 50)

      r.cell(0, 0).grapheme.should eq("R")
      r.cell(3, 0).grapheme.should eq("5")
      r.cell(4, 0).grapheme.should eq("0")
      r.cell(0, 1).grapheme.should eq("R")
      r.cell(4, 1).grapheme.should eq("1")
    end

    it "applies scroll_x offset" do
      vp = CRT::Ansi::Viewport.new(width: 50, height: 5)
      vp.write(0, 0, "ABCDEFGHIJ")

      r = render(10, 5)
      r.blit(vp, x: 0, y: 0, w: 5, h: 1, scroll_x: 3)

      r.cell(0, 0).grapheme.should eq("D")
      r.cell(4, 0).grapheme.should eq("H")
    end

    it "clips to viewport bounds" do
      vp = CRT::Ansi::Viewport.new(width: 5, height: 3)
      vp.write(0, 0, "Hello")
      vp.write(0, 1, "World")
      vp.write(0, 2, "Yay!!")

      r = render(10, 10)
      r.blit(vp, x: 0, y: 0, w: 8, h: 5, scroll_y: 1)

      r.cell(0, 0).grapheme.should eq("W")
      r.cell(0, 1).grapheme.should eq("Y")
      r.cell(0, 2).blank?.should be_true
    end

    it "handles negative scroll gracefully" do
      vp = CRT::Ansi::Viewport.new(width: 10, height: 5)
      vp.write(0, 0, "Hello")

      r = render(10, 5)
      r.blit(vp, x: 0, y: 0, w: 5, h: 3, scroll_y: -1)

      r.cell(0, 0).blank?.should be_true
      r.cell(0, 1).grapheme.should eq("H")
    end

    it "preserves styles" do
      bold = CRT::Ansi::Style.new(bold: true)
      vp = CRT::Ansi::Viewport.new(width: 10, height: 5)
      vp.write(0, 0, "Hi", bold)

      r = render(10, 5)
      r.blit(vp, x: 0, y: 0, w: 5, h: 1)

      r.cell(0, 0).style.should eq(bold)
      r.cell(1, 0).style.should eq(bold)
    end
  end

  describe "Canvas methods" do
    it "supports box drawing" do
      vp = CRT::Ansi::Viewport.new(width: 10, height: 5)
      vp.box(0, 0, w: 5, h: 3)

      vp.cell(0, 0).grapheme.should eq("┌")
      vp.cell(4, 0).grapheme.should eq("┐")
      vp.cell(0, 2).grapheme.should eq("└")
      vp.cell(4, 2).grapheme.should eq("┘")
    end

    it "supports panel drawing" do
      vp = CRT::Ansi::Viewport.new(width: 20, height: 10)
      vp.panel(0, 0, w: 10, h: 3).border.text("Hi").draw

      vp.cell(0, 0).grapheme.should eq("┌")
      vp.cell(1, 1).grapheme.should eq("H")
      vp.cell(2, 1).grapheme.should eq("i")
    end
  end

  describe "#resize" do
    it "creates a new buffer with new dimensions" do
      vp = CRT::Ansi::Viewport.new(width: 5, height: 3)
      vp.write(0, 0, "Hello")
      vp.resize(10, 8)

      vp.width.should eq(10)
      vp.height.should eq(8)
      vp.cell(0, 0).blank?.should be_true
    end
  end

  describe "#width / #height" do
    it "returns the virtual buffer dimensions" do
      vp = CRT::Ansi::Viewport.new(width: 80, height: 200)
      vp.width.should eq(80)
      vp.height.should eq(200)
    end
  end
end
