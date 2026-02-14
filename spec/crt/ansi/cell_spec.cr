require "../../spec_helper"

describe CRT::Ansi::Cell do
  describe ".blank" do
    it "creates a space cell with width 1" do
      cell = CRT::Ansi::Cell.blank
      cell.grapheme.should eq(" ")
      cell.width.should eq(1)
      cell.continuation?.should be_false
      cell.blank?.should be_true
    end

    it "accepts a custom style" do
      style = CRT::Ansi::Style.new(bold: true)
      cell = CRT::Ansi::Cell.blank(style)
      cell.style.bold.should be_true
      cell.blank?.should be_true
    end
  end

  describe ".continuation" do
    it "creates a zero-width continuation marker" do
      cell = CRT::Ansi::Cell.continuation
      cell.grapheme.should eq("")
      cell.width.should eq(0)
      cell.continuation?.should be_true
      cell.blank?.should be_false
    end
  end

  describe "#blank?" do
    it "returns false for non-space graphemes" do
      cell = CRT::Ansi::Cell.new(grapheme: "A")
      cell.blank?.should be_false
    end

    it "returns false for wide spaces" do
      cell = CRT::Ansi::Cell.new(grapheme: " ", width: 2)
      cell.blank?.should be_false
    end
  end

  describe "equality" do
    it "compares by value" do
      a = CRT::Ansi::Cell.new(grapheme: "X", width: 1)
      b = CRT::Ansi::Cell.new(grapheme: "X", width: 1)
      a.should eq(b)
    end

    it "differs when grapheme differs" do
      a = CRT::Ansi::Cell.new(grapheme: "X")
      b = CRT::Ansi::Cell.new(grapheme: "Y")
      a.should_not eq(b)
    end

    it "differs when style differs" do
      a = CRT::Ansi::Cell.new(grapheme: "X")
      b = CRT::Ansi::Cell.new(grapheme: "X", style: CRT::Ansi::Style.new(bold: true))
      a.should_not eq(b)
    end
  end
end
