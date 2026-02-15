require "../../spec_helper"

private def render(w = 20, h = 1)
  CRT::Ansi::Render.new(IO::Memory.new, w, h)
end

describe CRT::Ansi::EditLine do
  describe "construction" do
    it "starts with empty text and cursor at 0" do
      line = CRT::Ansi::EditLine.new
      line.text.should eq("")
      line.cursor.should eq(0)
      line.scroll.should eq(0)
    end

    it "accepts initial text" do
      line = CRT::Ansi::EditLine.new("Hello")
      line.text.should eq("Hello")
      line.cursor.should eq(0)
    end
  end

  describe "#text=" do
    it "updates text" do
      line = CRT::Ansi::EditLine.new("Hello")
      line.text = "World"
      line.text.should eq("World")
    end

    it "clamps cursor when text shrinks" do
      line = CRT::Ansi::EditLine.new("Hello")
      line.cursor = 5
      line.text = "Hi"
      line.cursor.should eq(2)
    end
  end

  describe "#cursor=" do
    it "clamps to valid range" do
      line = CRT::Ansi::EditLine.new("Hello")
      line.cursor = 100
      line.cursor.should eq(5)
      line.cursor = -5
      line.cursor.should eq(0)
    end
  end

  describe "queries" do
    it "grapheme_count returns correct count" do
      line = CRT::Ansi::EditLine.new("Hello")
      line.grapheme_count.should eq(5)
    end

    it "display_width returns total width" do
      line = CRT::Ansi::EditLine.new("a\u{4E2D}b")
      line.display_width.should eq(4) # 1 + 2 + 1
    end

    it "cursor_column returns display column at cursor" do
      line = CRT::Ansi::EditLine.new("a\u{4E2D}b")
      line.cursor = 2 # after "a" and "中"
      line.cursor_column.should eq(3)
    end
  end

  describe "#insert" do
    it "inserts at beginning" do
      line = CRT::Ansi::EditLine.new("ello")
      line.insert("H")
      line.text.should eq("Hello")
      line.cursor.should eq(1)
    end

    it "inserts at middle" do
      line = CRT::Ansi::EditLine.new("Hllo")
      line.cursor = 1
      line.insert("e")
      line.text.should eq("Hello")
      line.cursor.should eq(2)
    end

    it "inserts at end" do
      line = CRT::Ansi::EditLine.new("Hell")
      line.cursor = 4
      line.insert("o")
      line.text.should eq("Hello")
      line.cursor.should eq(5)
    end
  end

  describe "#delete_before" do
    it "deletes before cursor" do
      line = CRT::Ansi::EditLine.new("Hello")
      line.cursor = 3
      line.delete_before
      line.text.should eq("Helo")
      line.cursor.should eq(2)
    end

    it "is no-op at position 0" do
      line = CRT::Ansi::EditLine.new("Hello")
      line.delete_before
      line.text.should eq("Hello")
      line.cursor.should eq(0)
    end
  end

  describe "#delete_at" do
    it "deletes at cursor" do
      line = CRT::Ansi::EditLine.new("Hello")
      line.cursor = 2
      line.delete_at
      line.text.should eq("Helo")
      line.cursor.should eq(2)
    end

    it "is no-op at end" do
      line = CRT::Ansi::EditLine.new("Hello")
      line.cursor = 5
      line.delete_at
      line.text.should eq("Hello")
    end
  end

  describe "cursor movement" do
    it "move_left decrements cursor" do
      line = CRT::Ansi::EditLine.new("Hello")
      line.cursor = 3
      line.move_left
      line.cursor.should eq(2)
    end

    it "move_left at 0 stays at 0" do
      line = CRT::Ansi::EditLine.new("Hello")
      line.move_left
      line.cursor.should eq(0)
    end

    it "move_right increments cursor" do
      line = CRT::Ansi::EditLine.new("Hello")
      line.move_right
      line.cursor.should eq(1)
    end

    it "move_right at end stays at end" do
      line = CRT::Ansi::EditLine.new("Hello")
      line.cursor = 5
      line.move_right
      line.cursor.should eq(5)
    end

    it "move_home goes to 0" do
      line = CRT::Ansi::EditLine.new("Hello")
      line.cursor = 3
      line.move_home
      line.cursor.should eq(0)
    end

    it "move_end goes to grapheme count" do
      line = CRT::Ansi::EditLine.new("Hello")
      line.move_end
      line.cursor.should eq(5)
    end

    it "move_to_column positions cursor by display column" do
      line = CRT::Ansi::EditLine.new("Hello")
      line.move_to_column(3)
      line.cursor.should eq(3)
    end

    it "move_to_column handles wide characters" do
      line = CRT::Ansi::EditLine.new("a\u{4E2D}b")
      # col 0=a, col 1-2=中, col 3=b
      line.move_to_column(2)
      line.cursor.should eq(1) # still on 中
    end

    it "move_to_column past end goes to grapheme count" do
      line = CRT::Ansi::EditLine.new("Hi")
      line.move_to_column(20)
      line.cursor.should eq(2)
    end
  end

  describe "#render" do
    it "renders text at specified position" do
      line = CRT::Ansi::EditLine.new("Hello")
      r = render(20, 1)
      line.render(r, 2, 0, 10, CRT::Ansi::Style.default)

      r.cell(2, 0).grapheme.should eq("H")
      r.cell(3, 0).grapheme.should eq("e")
      r.cell(6, 0).grapheme.should eq("o")
    end

    it "applies cursor style at cursor position" do
      line = CRT::Ansi::EditLine.new("Hello")
      r = render(20, 1)
      line.render(r, 0, 0, 10, CRT::Ansi::Style.default, CRT::Ansi::Style::INVERSE)

      r.cell(0, 0).style.inverse.should be_true  # cursor at 0
      r.cell(1, 0).style.inverse.should be_false
    end

    it "no cursor styling when cursor_style is nil" do
      line = CRT::Ansi::EditLine.new("Hello")
      r = render(20, 1)
      line.render(r, 0, 0, 10, CRT::Ansi::Style.default, nil)

      r.cell(0, 0).style.inverse.should be_false
    end

    it "renders inverse space at end of text" do
      line = CRT::Ansi::EditLine.new("Hi")
      line.cursor = 2
      r = render(20, 1)
      line.render(r, 0, 0, 10, CRT::Ansi::Style.default, CRT::Ansi::Style::INVERSE)

      r.cell(2, 0).grapheme.should eq(" ")
      r.cell(2, 0).style.inverse.should be_true
    end

    it "scrolls to keep cursor visible" do
      line = CRT::Ansi::EditLine.new("abcdefghij")
      line.cursor = 8 # past visible area of width 5
      r = render(20, 1)
      line.render(r, 0, 0, 5, CRT::Ansi::Style.default, CRT::Ansi::Style::INVERSE)

      # Cursor at grapheme 8 ("i"), display col 8
      # Scroll should adjust so cursor is visible within width 5
      # The cell at cursor should have inverse style
      visible = (0...5).map { |cx| r.cell(cx, 0) }
      visible.any? { |c| c.style.inverse }.should be_true
    end

    it "scrolls back when cursor moves left" do
      line = CRT::Ansi::EditLine.new("abcdefghij")
      line.cursor = 8
      r = render(20, 1)
      line.render(r, 0, 0, 5, CRT::Ansi::Style.default, CRT::Ansi::Style::INVERSE)

      # Now move back to start
      line.cursor = 0
      r2 = render(20, 1)
      line.render(r2, 0, 0, 5, CRT::Ansi::Style.default, CRT::Ansi::Style::INVERSE)

      r2.cell(0, 0).grapheme.should eq("a")
      r2.cell(0, 0).style.inverse.should be_true
    end
  end
end
