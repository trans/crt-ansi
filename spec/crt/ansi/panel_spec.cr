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

      r.cell(1, 1).grapheme.should eq(" ")
      r.cell(1, 1).style.should eq(bg)
      r.cell(3, 1).style.should eq(bg)
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
      r.cell(7, 1).grapheme.should_not eq("W")
    end

    it "writes text without border using full area" do
      r = renderer
      r.panel(0, 0, h: 10, v: 3).text("Hello").draw

      r.cell(0, 0).grapheme.should eq("H")
      r.cell(4, 0).grapheme.should eq("o")
    end
  end

  describe "Wrap::None with newlines" do
    it "splits on explicit newlines" do
      r = renderer(20, 10)
      r.panel(0, 0, h: 12, v: 5).border.text("line one\nline two").draw

      r.cell(1, 1).grapheme.should eq("l")
      r.cell(6, 1).grapheme.should eq("o")
      r.cell(1, 2).grapheme.should eq("l")
      r.cell(6, 2).grapheme.should eq("t")
    end

    it "truncates long lines without wrapping" do
      r = renderer(20, 10)
      r.panel(0, 0, h: 7, v: 4).border.text("abcdefghij\nxy").draw

      # Interior width = 5, "abcde" visible, "fghij" clipped
      r.cell(1, 1).grapheme.should eq("a")
      r.cell(5, 1).grapheme.should eq("e")
      # Second line
      r.cell(1, 2).grapheme.should eq("x")
      r.cell(2, 2).grapheme.should eq("y")
    end
  end

  describe "Wrap::Word" do
    it "wraps text at word boundaries" do
      r = renderer(20, 10)
      r.panel(0, 0, h: 12, v: 6).border.text("one two three four five", wrap: CRT::Ansi::Wrap::Word).draw

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
      r.panel(0, 0, h: 12, v: 5).border.text("line one\nline two", wrap: CRT::Ansi::Wrap::Word).draw

      r.cell(1, 1).grapheme.should eq("l")
      r.cell(6, 1).grapheme.should eq("o")
      r.cell(1, 2).grapheme.should eq("l")
      r.cell(6, 2).grapheme.should eq("t")
    end

    it "breaks long words" do
      r = renderer(20, 10)
      r.panel(0, 0, h: 7, v: 5).border.text("abcdefghij", wrap: CRT::Ansi::Wrap::Word).draw

      # Interior width = 5
      r.cell(1, 1).grapheme.should eq("a")
      r.cell(5, 1).grapheme.should eq("e")
      r.cell(1, 2).grapheme.should eq("f")
    end

    it "clips text that exceeds height" do
      r = renderer(20, 10)
      r.panel(0, 0, h: 8, v: 4).border.text("a b c d e f g h", wrap: CRT::Ansi::Wrap::Word).draw

      # Interior height = 2
      r.cell(1, 1).grapheme.should_not eq("")
      r.cell(1, 2).grapheme.should_not eq("")
    end
  end

  describe "Wrap::Char" do
    it "wraps at exact character width" do
      r = renderer(20, 10)
      r.panel(0, 0, h: 7, v: 5).border.text("abcdefghij", wrap: CRT::Ansi::Wrap::Char).draw

      # Interior width = 5
      # Line 1: "abcde"
      r.cell(1, 1).grapheme.should eq("a")
      r.cell(5, 1).grapheme.should eq("e")
      # Line 2: "fghij"
      r.cell(1, 2).grapheme.should eq("f")
      r.cell(5, 2).grapheme.should eq("j")
    end

    it "does not break at word boundaries" do
      r = renderer(20, 10)
      r.panel(0, 0, h: 7, v: 5).border.text("ab cd ef", wrap: CRT::Ansi::Wrap::Char).draw

      # Interior width = 5
      # Line 1: "ab cd" → a,b, ,c,d
      r.cell(1, 1).grapheme.should eq("a")
      r.cell(2, 1).grapheme.should eq("b")
      r.cell(3, 1).grapheme.should eq(" ")
      r.cell(4, 1).grapheme.should eq("c")
      r.cell(5, 1).grapheme.should eq("d")
      # Line 2: " ef" → space,e,f
      r.cell(1, 2).grapheme.should eq(" ")
      r.cell(2, 2).grapheme.should eq("e")
      r.cell(3, 2).grapheme.should eq("f")
    end

    it "preserves explicit newlines" do
      r = renderer(20, 10)
      r.panel(0, 0, h: 7, v: 5).border.text("abc\ndef", wrap: CRT::Ansi::Wrap::Char).draw

      r.cell(1, 1).grapheme.should eq("a")
      r.cell(3, 1).grapheme.should eq("c")
      r.cell(1, 2).grapheme.should eq("d")
      r.cell(3, 2).grapheme.should eq("f")
    end
  end

  describe "VAlign" do
    it "top-aligns by default (clips bottom)" do
      r = renderer(20, 10)
      r.panel(0, 0, h: 10, v: 4).border.text("a\nb\nc\nd\ne").draw

      # Interior height = 2, top-aligned: "a" and "b" visible
      r.cell(1, 1).grapheme.should eq("a")
      r.cell(1, 2).grapheme.should eq("b")
    end

    it "bottom-aligns (clips top)" do
      r = renderer(20, 10)
      r.panel(0, 0, h: 10, v: 4).border
        .text("a\nb\nc\nd\ne", valign: CRT::Ansi::VAlign::Bottom).draw

      # Interior height = 2, bottom-aligned: "d" and "e" visible
      r.cell(1, 1).grapheme.should eq("d")
      r.cell(1, 2).grapheme.should eq("e")
    end

    it "middle-aligns (clips both)" do
      r = renderer(20, 10)
      r.panel(0, 0, h: 10, v: 4).border
        .text("a\nb\nc\nd\ne", valign: CRT::Ansi::VAlign::Middle).draw

      # 5 lines, 2 visible, skip = (5-2)//2 = 1: "b" and "c" visible
      r.cell(1, 1).grapheme.should eq("b")
      r.cell(1, 2).grapheme.should eq("c")
    end

    it "does not clip when content fits" do
      r = renderer(20, 10)
      r.panel(0, 0, h: 10, v: 5).border
        .text("a\nb\nc", valign: CRT::Ansi::VAlign::Middle).draw

      # 3 lines in interior height 3 — no clipping needed
      r.cell(1, 1).grapheme.should eq("a")
      r.cell(1, 2).grapheme.should eq("b")
      r.cell(1, 3).grapheme.should eq("c")
    end
  end

  describe "ellipsis" do
    it "appends ellipsis when left-aligned text overflows" do
      r = renderer(20, 5)
      r.panel(0, 0, h: 10, v: 3).border
        .text("Hello World!", ellipsis: "…").draw

      # Interior width = 8, ellipsis = 1, avail = 7
      # "Hello W" + "…"
      r.cell(1, 1).grapheme.should eq("H")
      r.cell(7, 1).grapheme.should eq("W")
      r.cell(8, 1).grapheme.should eq("…")
    end

    it "prepends ellipsis when right-aligned text overflows" do
      r = renderer(20, 5)
      r.panel(0, 0, h: 10, v: 3).border
        .text("Hello World!", align: CRT::Ansi::Align::Right, ellipsis: "…").draw

      # Interior width = 8, ellipsis = 1, avail = 7
      # "…" + last 7 chars "World!"
      r.cell(1, 1).grapheme.should eq("…")
    end

    it "does not add ellipsis when text fits" do
      r = renderer(20, 5)
      r.panel(0, 0, h: 10, v: 3).border
        .text("Hi", ellipsis: "…").draw

      r.cell(1, 1).grapheme.should eq("H")
      r.cell(2, 1).grapheme.should eq("i")
      r.cell(3, 1).grapheme.should_not eq("…")
    end
  end

  describe "alignment-aware clipping" do
    it "clips right side for left-aligned overflow" do
      r = renderer(20, 5)
      r.panel(0, 0, h: 7, v: 3).border.text("abcdefgh").draw

      # Interior width = 5, shows "abcde"
      r.cell(1, 1).grapheme.should eq("a")
      r.cell(5, 1).grapheme.should eq("e")
    end

    it "clips left side for right-aligned overflow" do
      r = renderer(20, 5)
      r.panel(0, 0, h: 7, v: 3).border
        .text("abcdefgh", align: CRT::Ansi::Align::Right).draw

      # Interior width = 5, right-aligned clips left: shows "defgh"
      r.cell(1, 1).grapheme.should eq("d")
      r.cell(5, 1).grapheme.should eq("h")
    end

    it "clips both sides for center-aligned overflow" do
      r = renderer(20, 5)
      r.panel(0, 0, h: 7, v: 3).border
        .text("abcdefgh", align: CRT::Ansi::Align::Center).draw

      # Interior width = 5, center clips: skip = (8-5)//2 = 1, shows "bcdef"
      r.cell(1, 1).grapheme.should eq("b")
      r.cell(5, 1).grapheme.should eq("f")
    end
  end

  describe "StyledText" do
    it "renders styled spans" do
      r = renderer(20, 5)
      bold = CRT::Ansi::Style.new(bold: true)
      red = CRT::Ansi::Style.new(fg: CRT::Ansi::Color.indexed(1))
      text = CRT::Ansi::StyledText.new
        .add("He", bold)
        .add("lo", red)

      r.panel(0, 0, h: 10, v: 3).border.text(text).draw

      r.cell(1, 1).grapheme.should eq("H")
      r.cell(1, 1).style.should eq(bold)
      r.cell(2, 1).grapheme.should eq("e")
      r.cell(2, 1).style.should eq(bold)
      r.cell(3, 1).grapheme.should eq("l")
      r.cell(3, 1).style.should eq(red)
      r.cell(4, 1).grapheme.should eq("o")
      r.cell(4, 1).style.should eq(red)
    end

    it "preserves styles through word wrap" do
      r = renderer(20, 10)
      bold = CRT::Ansi::Style.new(bold: true)
      normal = CRT::Ansi::Style.default
      text = CRT::Ansi::StyledText.new
        .add("one ", bold)
        .add("two three", normal)

      r.panel(0, 0, h: 9, v: 5).border.text(text, wrap: CRT::Ansi::Wrap::Word).draw

      # Interior width = 7: "one two" on line 1, "three" on line 2
      # "one" should be bold
      r.cell(1, 1).grapheme.should eq("o")
      r.cell(1, 1).style.should eq(bold)
      # "two" should be normal
      r.cell(5, 1).grapheme.should eq("t")
      r.cell(5, 1).style.should eq(normal)
      # "three" on next line, normal
      r.cell(1, 2).grapheme.should eq("t")
      r.cell(1, 2).style.should eq(normal)
    end

    it "splits styled text on newlines" do
      r = renderer(20, 10)
      bold = CRT::Ansi::Style.new(bold: true)
      text = CRT::Ansi::StyledText.new
        .add("a\nb", bold)

      r.panel(0, 0, h: 10, v: 4).border.text(text).draw

      r.cell(1, 1).grapheme.should eq("a")
      r.cell(1, 1).style.should eq(bold)
      r.cell(1, 2).grapheme.should eq("b")
      r.cell(1, 2).style.should eq(bold)
    end
  end

  describe "#shadow" do
    it "draws shadow cells offset from box" do
      r = renderer
      r.panel(1, 1, h: 4, v: 3).border.shadow.draw

      shadow_style = CRT::Ansi::Style.new(bg: CRT::Ansi::Color.indexed(0))
      r.cell(5, 2).style.should eq(shadow_style)
      r.cell(5, 3).style.should eq(shadow_style)
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

      r.cell(3, 1).grapheme.should eq("H")
      r.cell(4, 1).grapheme.should eq("i")
    end
  end
end
