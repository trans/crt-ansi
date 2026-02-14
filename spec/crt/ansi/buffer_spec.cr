require "../../spec_helper"

describe CRT::Ansi::Buffer do
  it "handles wide graphemes with continuation cells" do
    buffer = CRT::Ansi::Buffer.new(5, 1)
    buffer.write(0, 0, "A\u{1F44D}B")

    buffer.cell(0, 0).grapheme.should eq("A")
    buffer.cell(1, 0).grapheme.should eq("\u{1F44D}")
    buffer.cell(2, 0).continuation?.should be_true
    buffer.cell(3, 0).grapheme.should eq("B")
  end

  it "sanitizes control graphemes to spaces" do
    buffer = CRT::Ansi::Buffer.new(2, 1)
    buffer.put(0, 0, "\e")
    buffer.cell(0, 0).grapheme.should eq(" ")
  end
end
