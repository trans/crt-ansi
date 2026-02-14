require "../../spec_helper"

private def renderer(w = 20, h = 10)
  CRT::Ansi::Renderer.new(IO::Memory.new, w, h)
end

describe CRT::Ansi::Panel do
  describe "#border" do
    it "draws a border on .draw" do
      r = renderer
      r.panel(0, 0, h: 5, v: 3).border.draw
      r.cell(0, 0).grapheme.should eq("┌")
      r.cell(4, 0).grapheme.should eq("┐")
      r.cell(0, 2).grapheme.should eq("└")
      r.cell(4, 2).grapheme.should eq("┘")
    end

    it "supports border styles" do
      r = renderer
      r.panel(0, 0, h: 5, v: 3).border(CRT::Ansi::Border::Rounded).draw
      r.cell(0, 0).grapheme.should eq("╭")
      r.cell(4, 0).grapheme.should eq("╮")
    end
  end

  describe "#fill" do
    it "fills interior within border" do
      r = renderer
      bg = CRT::Ansi::Style.new(bg: CRT::Ansi::Color.indexed(1))
      r.panel(0, 0, h: 5, v: 3).border.fill(bg).draw

      # Interior cells filled
      r.cell(1, 1).grapheme.should eq(" ")
      r.cell(1, 1).style.should eq(bg)
      r.cell(3, 1).style.should eq(bg)

      # Border cells not affected by fill style
      r.cell(0, 0).grapheme.should eq("┌")
    end

    it "fills full area without border" do
      r = renderer
      bg = CRT::Ansi::Style.new(bg: CRT::Ansi::Color.indexed(2))
      r.panel(0, 0, h: 4, v: 2).fill(bg).draw

      r.cell(0, 0).style.should eq(bg)
      r.cell(3, 1).style.should eq(bg)
    end

    it "fills with a StyleChar" do
      r = renderer
      r.panel(0, 0, h: 5, v: 3).border.fill(CRT::Ansi::StyleChar.new('·')).draw

      r.cell(1, 1).grapheme.should eq("·")
      r.cell(2, 1).grapheme.should eq("·")
    end
  end

  describe "#text" do
    it "writes left-aligned text inside border" do
      r = renderer
      r.panel(0, 0, h: 10, v: 3).border.text("Hi").draw

      r.cell(1, 1).grapheme.should eq("H")
      r.cell(2, 1).grapheme.should eq("i")
    end

    it "writes center-aligned text" do
      r = renderer
      r.panel(0, 0, h: 12, v: 3).border.text("Hi", align: CRT::Ansi::Align::Center).draw

      # Interior width = 10, "Hi" is 2 chars, offset = 4
      r.cell(5, 1).grapheme.should eq("H")
      r.cell(6, 1).grapheme.should eq("i")
    end

    it "writes right-aligned text" do
      r = renderer
      r.panel(0, 0, h: 12, v: 3).border.text("Hi", align: CRT::Ansi::Align::Right).draw

      # Interior width = 10, "Hi" is 2 chars, offset = 8
      r.cell(9, 1).grapheme.should eq("H")
      r.cell(10, 1).grapheme.should eq("i")
    end

    it "truncates text that exceeds width" do
      r = renderer(15, 5)
      r.panel(0, 0, h: 8, v: 3).border.text("Hello World").draw

      # Interior width = 6, "Hello " fits, "W" would be 7th
      r.cell(1, 1).grapheme.should eq("H")
      r.cell(6, 1).grapheme.should eq(" ")
      # 7th char should not overflow past border
      r.cell(7, 1).grapheme.should_not eq("W")
    end

    it "writes text without border using full area" do
      r = renderer
      r.panel(0, 0, h: 10, v: 3).text("Hello").draw

      r.cell(0, 0).grapheme.should eq("H")
      r.cell(4, 0).grapheme.should eq("o")
    end
  end

  describe "#text with wrap" do
    it "wraps text at word boundaries" do
      r = renderer(20, 10)
      r.panel(0, 0, h: 12, v: 6).border.text("one two three four five", wrap: true).draw

      # Interior width = 10
      # Line 1: "one two"
      r.cell(1, 1).grapheme.should eq("o")
      # Line 2: "three four"
      r.cell(1, 2).grapheme.should eq("t")
      # Line 3: "five"
      r.cell(1, 3).grapheme.should eq("f")
    end

    it "preserves explicit newlines" do
      r = renderer(20, 10)
      r.panel(0, 0, h: 12, v: 5).border.text("line one\nline two", wrap: true).draw

      # "line one" at row 1 (border inset), starting at x=1
      r.cell(1, 1).grapheme.should eq("l")
      r.cell(6, 1).grapheme.should eq("o")
      # "line two" at row 2
      r.cell(1, 2).grapheme.should eq("l")
      r.cell(6, 2).grapheme.should eq("t")
    end

    it "breaks long words" do
      r = renderer(20, 10)
      r.panel(0, 0, h: 7, v: 5).border.text("abcdefghij", wrap: true).draw

      # Interior width = 5
      # Line 1: "abcde"
      r.cell(1, 1).grapheme.should eq("a")
      r.cell(5, 1).grapheme.should eq("e")
      # Line 2: "fghij"
      r.cell(1, 2).grapheme.should eq("f")
    end

    it "clips text that exceeds height" do
      r = renderer(20, 10)
      r.panel(0, 0, h: 8, v: 4).border.text("a b c d e f g h", wrap: true).draw

      # Interior height = 2, so only 2 lines visible
      r.cell(1, 1).grapheme.should_not eq("")
      r.cell(1, 2).grapheme.should_not eq("")
    end
  end

  describe "#shadow" do
    it "draws shadow cells offset from box" do
      r = renderer
      r.panel(1, 1, h: 4, v: 3).border.shadow.draw

      shadow_style = CRT::Ansi::Style.new(bg: CRT::Ansi::Color.indexed(0))
      # Right edge shadow
      r.cell(5, 2).style.should eq(shadow_style)
      r.cell(5, 3).style.should eq(shadow_style)
      # Bottom edge shadow
      r.cell(2, 4).style.should eq(shadow_style)
      r.cell(4, 4).style.should eq(shadow_style)
    end
  end

  describe "chaining order independence" do
    it "produces the same result regardless of chain order" do
      bg = CRT::Ansi::Style.new(bg: CRT::Ansi::Color.indexed(4))

      r1 = renderer
      r1.panel(0, 0, h: 10, v: 4).border.fill(bg).text("Hi").draw

      r2 = renderer
      r2.panel(0, 0, h: 10, v: 4).text("Hi").fill(bg).border.draw

      # Same result
      4.times do |y|
        10.times do |x|
          r1.cell(x, y).should eq(r2.cell(x, y))
        end
      end
    end
  end

  describe "#text with pad" do
    it "adds horizontal padding to text" do
      r = renderer
      r.panel(0, 0, h: 14, v: 3).border.text("Hi", pad: 2).draw

      # Border inset = 1, pad = 2, so text starts at x=3
      r.cell(3, 1).grapheme.should eq("H")
      r.cell(4, 1).grapheme.should eq("i")
    end
  end
end
