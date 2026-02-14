require "../../spec_helper"

describe CRT::Ansi::StyledText do
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
