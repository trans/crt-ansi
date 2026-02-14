require "../../spec_helper"

describe CRT::Ansi::Buffer do
  describe "#put" do
    it "places a single grapheme at given coordinates" do
      buffer = CRT::Ansi::Buffer.new(3, 1)
      buffer.put(1, 0, "X")
      buffer.cell(1, 0).grapheme.should eq("X")
    end

    it "sanitizes control graphemes to spaces" do
      buffer = CRT::Ansi::Buffer.new(2, 1)
      buffer.put(0, 0, "\e")
      buffer.cell(0, 0).grapheme.should eq(" ")
    end

    it "silently ignores out-of-bounds coordinates" do
      buffer = CRT::Ansi::Buffer.new(3, 3)
      buffer.put(-1, 0, "X")   # no crash
      buffer.put(0, -1, "X")   # no crash
      buffer.put(3, 0, "X")    # no crash
      buffer.put(0, 3, "X")    # no crash
    end

    it "clamps wide grapheme at right edge to width 1" do
      buffer = CRT::Ansi::Buffer.new(3, 1)
      buffer.put(2, 0, "\u{4E2D}")  # CJK char, normally width 2
      buffer.cell(2, 0).width.should eq(1)
    end

    it "applies style to the placed cell" do
      buffer = CRT::Ansi::Buffer.new(3, 1)
      style = CRT::Ansi::Style.new(bold: true)
      buffer.put(0, 0, "A", style)
      buffer.cell(0, 0).style.bold.should be_true
    end
  end

  describe "#write" do
    it "handles wide graphemes with continuation cells" do
      buffer = CRT::Ansi::Buffer.new(5, 1)
      buffer.write(0, 0, "A\u{1F44D}B")

      buffer.cell(0, 0).grapheme.should eq("A")
      buffer.cell(1, 0).grapheme.should eq("\u{1F44D}")
      buffer.cell(2, 0).continuation?.should be_true
      buffer.cell(3, 0).grapheme.should eq("B")
    end

    it "returns the cursor x position after writing" do
      buffer = CRT::Ansi::Buffer.new(10, 1)
      cursor = buffer.write(0, 0, "Hello")
      cursor.should eq(5)
    end

    it "expands tabs to 4-column stops" do
      buffer = CRT::Ansi::Buffer.new(10, 1)
      buffer.write(0, 0, "A\tB")
      # A at 0, tab fills 1,2,3, B at 4
      buffer.cell(0, 0).grapheme.should eq("A")
      buffer.cell(1, 0).grapheme.should eq(" ")
      buffer.cell(2, 0).grapheme.should eq(" ")
      buffer.cell(3, 0).grapheme.should eq(" ")
      buffer.cell(4, 0).grapheme.should eq("B")
    end

    it "stops at newlines" do
      buffer = CRT::Ansi::Buffer.new(10, 1)
      cursor = buffer.write(0, 0, "AB\nCD")
      cursor.should eq(2)
      buffer.cell(0, 0).grapheme.should eq("A")
      buffer.cell(1, 0).grapheme.should eq("B")
      buffer.cell(2, 0).blank?.should be_true
    end

    it "clips at buffer width" do
      buffer = CRT::Ansi::Buffer.new(3, 1)
      cursor = buffer.write(0, 0, "ABCDE")
      cursor.should eq(3)
      buffer.cell(0, 0).grapheme.should eq("A")
      buffer.cell(1, 0).grapheme.should eq("B")
      buffer.cell(2, 0).grapheme.should eq("C")
    end

    it "applies style to all written cells" do
      buffer = CRT::Ansi::Buffer.new(5, 1)
      style = CRT::Ansi::Style.new(italic: true)
      buffer.write(0, 0, "Hi", style)
      buffer.cell(0, 0).style.italic.should be_true
      buffer.cell(1, 0).style.italic.should be_true
    end

    it "handles out-of-bounds y gracefully" do
      buffer = CRT::Ansi::Buffer.new(5, 2)
      cursor = buffer.write(0, 5, "Hello")
      cursor.should eq(0)
    end
  end

  describe "wide char overwriting" do
    it "detaches previous wide char when overwriting its continuation" do
      buffer = CRT::Ansi::Buffer.new(4, 1)
      buffer.put(0, 0, "\u{4E2D}")  # wide char at 0,1
      buffer.cell(0, 0).width.should eq(2)
      buffer.cell(1, 0).continuation?.should be_true

      # Overwrite the continuation cell
      buffer.put(1, 0, "X")
      buffer.cell(0, 0).blank?.should be_true  # head detached
      buffer.cell(1, 0).grapheme.should eq("X")
    end

    it "detaches continuation when overwriting wide char head" do
      buffer = CRT::Ansi::Buffer.new(4, 1)
      buffer.put(1, 0, "\u{4E2D}")  # wide char at 1,2
      buffer.cell(2, 0).continuation?.should be_true

      buffer.put(1, 0, "Y")
      buffer.cell(1, 0).grapheme.should eq("Y")
      buffer.cell(2, 0).blank?.should be_true  # continuation detached
    end
  end

  describe "#clear" do
    it "resets all cells to blank" do
      buffer = CRT::Ansi::Buffer.new(3, 2)
      buffer.write(0, 0, "ABC")
      buffer.write(0, 1, "DEF")
      buffer.clear

      buffer.cell(0, 0).blank?.should be_true
      buffer.cell(2, 1).blank?.should be_true
    end

    it "applies the given style to cleared cells" do
      buffer = CRT::Ansi::Buffer.new(2, 1)
      style = CRT::Ansi::Style.new(bold: true)
      buffer.clear(style)
      buffer.cell(0, 0).style.bold.should be_true
    end
  end

  describe "#copy_from" do
    it "copies all cells from another buffer" do
      src = CRT::Ansi::Buffer.new(3, 1)
      dst = CRT::Ansi::Buffer.new(3, 1)
      src.write(0, 0, "XYZ")
      dst.copy_from(src)

      dst.cell(0, 0).grapheme.should eq("X")
      dst.cell(1, 0).grapheme.should eq("Y")
      dst.cell(2, 0).grapheme.should eq("Z")
    end

    it "rejects dimension mismatches" do
      a = CRT::Ansi::Buffer.new(3, 1)
      b = CRT::Ansi::Buffer.new(4, 1)
      expect_raises(ArgumentError) { a.copy_from(b) }
    end
  end

  describe "#==" do
    it "returns true for identical buffers" do
      a = CRT::Ansi::Buffer.new(3, 1)
      b = CRT::Ansi::Buffer.new(3, 1)
      a.write(0, 0, "AB")
      b.write(0, 0, "AB")
      (a == b).should be_true
    end

    it "returns false for different content" do
      a = CRT::Ansi::Buffer.new(3, 1)
      b = CRT::Ansi::Buffer.new(3, 1)
      a.write(0, 0, "AB")
      b.write(0, 0, "CD")
      (a == b).should be_false
    end
  end

  describe "constructor validation" do
    it "rejects zero or negative dimensions" do
      expect_raises(ArgumentError) { CRT::Ansi::Buffer.new(0, 1) }
      expect_raises(ArgumentError) { CRT::Ansi::Buffer.new(1, 0) }
      expect_raises(ArgumentError) { CRT::Ansi::Buffer.new(-1, 1) }
    end
  end

  describe "#cell" do
    it "raises IndexError for out-of-bounds access" do
      buffer = CRT::Ansi::Buffer.new(3, 3)
      expect_raises(IndexError) { buffer.cell(3, 0) }
      expect_raises(IndexError) { buffer.cell(0, 3) }
      expect_raises(IndexError) { buffer.cell(-1, 0) }
    end
  end
end
