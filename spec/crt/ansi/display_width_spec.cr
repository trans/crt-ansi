require "../../spec_helper"

describe CRT::Ansi::DisplayWidth do
  it "detects simple, combining, and wide graphemes" do
    CRT::Ansi::DisplayWidth.of("a").should eq(1)
    CRT::Ansi::DisplayWidth.of("e\u0301").should eq(1)
    CRT::Ansi::DisplayWidth.of("\u{1F44D}").should eq(2)
    CRT::Ansi::DisplayWidth.of("\u{1F44D}\u{1F3FC}").should eq(2)
    CRT::Ansi::DisplayWidth.of("\u{4E2D}").should eq(2)
  end
end
