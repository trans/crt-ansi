require "../../spec_helper"

private alias Part = CRT::Ansi::StyledText::Part

describe CRT::Ansi::StyledText do
  describe ".new(Array(Part))" do
    it "applies styles to subsequent text" do
      bold = CRT::Ansi::Style.new(bold: true)
      text = CRT::Ansi::StyledText.new(["plain ", bold, "bold"] of Part)

      text.spans.size.should eq(2)
      text.spans[0].text.should eq("plain ")
      text.spans[0].style.should eq(CRT::Ansi::Style.default)
      text.spans[1].text.should eq("bold")
      text.spans[1].style.bold.should be_true
    end

    it "merges nested styles additively" do
      bold = CRT::Ansi::Style.new(bold: true)
      red = CRT::Ansi::Style.new(fg: CRT::Ansi::Color.indexed(1))
      text = CRT::Ansi::StyledText.new([bold, red, "bold+red"] of Part)

      text.spans.size.should eq(1)
      text.spans[0].style.bold.should be_true
      text.spans[0].style.fg.should eq(CRT::Ansi::Color.indexed(1))
    end

    it "pops the style stack" do
      bold = CRT::Ansi::Style.new(bold: true)
      red = CRT::Ansi::Style.new(fg: CRT::Ansi::Color.indexed(1))
      pop = CRT::Ansi::StyledText::POP

      text = CRT::Ansi::StyledText.new([
        bold, "bold ", red, "bold+red", pop, " just bold",
      ] of Part)

      text.spans.size.should eq(3)
      text.spans[0].style.bold.should be_true
      text.spans[0].style.fg.default?.should be_true

      text.spans[1].style.bold.should be_true
      text.spans[1].style.fg.should eq(CRT::Ansi::Color.indexed(1))

      text.spans[2].text.should eq(" just bold")
      text.spans[2].style.bold.should be_true
      text.spans[2].style.fg.default?.should be_true
    end

    it "does not pop below the default" do
      pop = CRT::Ansi::StyledText::POP
      text = CRT::Ansi::StyledText.new([pop, pop, pop, "safe"] of Part)

      text.spans.size.should eq(1)
      text.spans[0].style.should eq(CRT::Ansi::Style.default)
    end

    it "resets the style stack" do
      bold = CRT::Ansi::Style.new(bold: true)
      red = CRT::Ansi::Style.new(fg: CRT::Ansi::Color.indexed(1))
      reset = CRT::Ansi::StyledText::RESET

      text = CRT::Ansi::StyledText.new([
        bold, red, "styled", reset, " plain",
      ] of Part)

      text.spans.size.should eq(2)
      text.spans[0].style.bold.should be_true
      text.spans[1].text.should eq(" plain")
      text.spans[1].style.should eq(CRT::Ansi::Style.default)
    end

    it "splices nested StyledText spans verbatim" do
      inner_style = CRT::Ansi::Style.new(italic: true)
      inner = CRT::Ansi::StyledText.new.add("inner", inner_style)

      bold = CRT::Ansi::Style.new(bold: true)
      text = CRT::Ansi::StyledText.new([bold, "outer ", inner, " more"] of Part)

      text.spans.size.should eq(3)
      text.spans[0].text.should eq("outer ")
      text.spans[0].style.bold.should be_true

      text.spans[1].text.should eq("inner")
      text.spans[1].style.should eq(inner_style)

      text.spans[2].text.should eq(" more")
      text.spans[2].style.bold.should be_true
    end

    it "emits StyleChar with its own style" do
      char_style = CRT::Ansi::Style.new(fg: CRT::Ansi::Color.indexed(2))
      sc = CRT::Ansi::StyleChar.new("*", char_style)

      bold = CRT::Ansi::Style.new(bold: true)
      text = CRT::Ansi::StyledText.new([bold, "text", sc, "more"] of Part)

      text.spans.size.should eq(3)
      text.spans[0].text.should eq("text")
      text.spans[0].style.bold.should be_true

      text.spans[1].text.should eq("*")
      text.spans[1].style.should eq(char_style)

      text.spans[2].text.should eq("more")
      text.spans[2].style.bold.should be_true
    end

    it "skips empty strings" do
      text = CRT::Ansi::StyledText.new(["", "hello", ""] of Part)
      text.spans.size.should eq(1)
      text.spans[0].text.should eq("hello")
    end

    it "handles empty array" do
      text = CRT::Ansi::StyledText.new([] of Part)
      text.empty?.should be_true
    end

    it "accepts a custom default style" do
      base = CRT::Ansi::Style.new(fg: CRT::Ansi::Color.indexed(7))
      reset = CRT::Ansi::StyledText::RESET
      bold = CRT::Ansi::Style.new(bold: true)

      text = CRT::Ansi::StyledText.new([bold, "styled", reset, "plain"] of Part, default: base)

      text.spans[0].style.bold.should be_true
      text.spans[0].style.fg.should eq(CRT::Ansi::Color.indexed(7))

      text.spans[1].text.should eq("plain")
      text.spans[1].style.should eq(base)
    end

    it "handles consecutive strings" do
      text = CRT::Ansi::StyledText.new(["hello", " ", "world"] of Part)
      text.spans.size.should eq(3)
      text.to_s.should eq("hello world")
    end
  end

  describe "#add" do
    it "builds styled text with spans" do
      text = CRT::Ansi::StyledText.new
        .add("Hello", CRT::Ansi::Style.new(bold: true))
        .add(" world", CRT::Ansi::Style.default)

      text.spans.size.should eq(2)
      text.spans[0].text.should eq("Hello")
      text.spans[0].style.bold.should be_true
      text.spans[1].text.should eq(" world")
    end
  end

  describe "#width" do
    it "sums display widths of all spans" do
      text = CRT::Ansi::StyledText.new
        .add("Hi", CRT::Ansi::Style.default)
        .add(" there", CRT::Ansi::Style.default)

      text.width.should eq(8)
    end

    it "handles wide characters" do
      text = CRT::Ansi::StyledText.new
        .add("\u{4e16}", CRT::Ansi::Style.default)  # 世 = 2 wide

      text.width.should eq(2)
    end
  end

  describe "#to_s" do
    it "concatenates all span text" do
      text = CRT::Ansi::StyledText.new
        .add("Hello", CRT::Ansi::Style.new(bold: true))
        .add(" world", CRT::Ansi::Style.default)

      text.to_s.should eq("Hello world")
    end
  end

  describe "#empty?" do
    it "is true for empty text" do
      CRT::Ansi::StyledText.new.empty?.should be_true
    end

    it "is true for spans with empty strings" do
      text = CRT::Ansi::StyledText.new.add("", CRT::Ansi::Style.default)
      text.empty?.should be_true
    end

    it "is false when any span has content" do
      text = CRT::Ansi::StyledText.new.add("x", CRT::Ansi::Style.default)
      text.empty?.should be_false
    end
  end

  describe "#each_grapheme" do
    it "yields graphemes with widths and styles" do
      bold = CRT::Ansi::Style.new(bold: true)
      normal = CRT::Ansi::Style.default
      text = CRT::Ansi::StyledText.new
        .add("AB", bold)
        .add("c", normal)

      result = [] of {String, Int32, CRT::Ansi::Style}
      text.each_grapheme { |g, w, s| result << {g, w, s} }

      result.size.should eq(3)
      result[0].should eq({"A", 1, bold})
      result[1].should eq({"B", 1, bold})
      result[2].should eq({"c", 1, normal})
    end
  end
end
