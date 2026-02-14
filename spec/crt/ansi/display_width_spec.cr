require "../../spec_helper"

describe CRT::Ansi::DisplayWidth do
  it "returns 1 for ASCII characters" do
    CRT::Ansi::DisplayWidth.of("a").should eq(1)
    CRT::Ansi::DisplayWidth.of("Z").should eq(1)
    CRT::Ansi::DisplayWidth.of("5").should eq(1)
    CRT::Ansi::DisplayWidth.of(" ").should eq(1)
  end

  it "returns 1 for empty string" do
    CRT::Ansi::DisplayWidth.of("").should eq(1)
  end

  it "returns 1 for base + combining marks" do
    CRT::Ansi::DisplayWidth.of("e\u0301").should eq(1)     # e + acute accent
    CRT::Ansi::DisplayWidth.of("a\u030A\u0303").should eq(1) # a + ring + tilde
  end

  it "returns 2 for CJK characters" do
    CRT::Ansi::DisplayWidth.of("\u{4E2D}").should eq(2)   # 中
    CRT::Ansi::DisplayWidth.of("\u{3042}").should eq(2)   # あ (hiragana)
    CRT::Ansi::DisplayWidth.of("\u{AC00}").should eq(2)   # 가 (hangul)
  end

  it "returns 2 for wide emoji" do
    CRT::Ansi::DisplayWidth.of("\u{1F44D}").should eq(2)  # thumbs up
    CRT::Ansi::DisplayWidth.of("\u{1F600}").should eq(2)  # grinning face
  end

  it "returns 2 for emoji with skin tone modifier" do
    CRT::Ansi::DisplayWidth.of("\u{1F44D}\u{1F3FC}").should eq(2)
  end

  it "promotes emoji with VS16 to width 2" do
    # Heart + VS16 (emoji presentation) → width 2
    CRT::Ansi::DisplayWidth.of("\u2764\uFE0F").should eq(2)
    # Information source + VS16
    CRT::Ansi::DisplayWidth.of("\u2139\uFE0F").should eq(2)
  end

  it "does not promote non-emoji with VS15 (text presentation)" do
    # Heart + VS15 stays width 1 (text presentation, not emoji)
    CRT::Ansi::DisplayWidth.of("\u2764\uFE0E").should eq(1)
  end

  it "returns 1 for control characters" do
    CRT::Ansi::DisplayWidth.of("\u0000").should eq(1)
    CRT::Ansi::DisplayWidth.of("\u001F").should eq(1)
  end

  it "returns 1 for fullwidth forms mapped correctly" do
    CRT::Ansi::DisplayWidth.of("\uFF21").should eq(2)  # Ａ (fullwidth A)
    CRT::Ansi::DisplayWidth.of("\uFF01").should eq(2)  # ！ (fullwidth !)
  end

  it "returns correct widths for boundary codepoints" do
    # Hangul Jamo (start of DOUBLEWIDTH range 0x1100)
    CRT::Ansi::DisplayWidth.of("\u{1100}").should eq(2)
    # Just before DOUBLEWIDTH range
    CRT::Ansi::DisplayWidth.of("\u{10FF}").should eq(1)
  end
end
