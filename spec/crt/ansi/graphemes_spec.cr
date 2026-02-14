require "../../spec_helper"

private def clusters(text : String) : Array(String)
  result = [] of String
  CRT::Ansi::Graphemes.each(text) { |c| result << c }
  result
end

describe CRT::Ansi::Graphemes do

  it "returns no clusters for empty strings" do
    clusters("").should eq([] of String)
  end

  it "splits ASCII into individual characters" do
    clusters("abc").should eq(["a", "b", "c"])
  end

  it "keeps combining marks with their base character" do
    # e + combining acute accent = single grapheme
    clusters("e\u0301").should eq(["e\u0301"])
  end

  it "keeps multiple combining marks together" do
    # a + combining ring above + combining tilde
    clusters("a\u030A\u0303").should eq(["a\u030A\u0303"])
  end

  it "joins ZWJ sequences into a single cluster" do
    # Family emoji: person + ZWJ + person + ZWJ + child
    family = "\u{1F468}\u200D\u{1F469}\u200D\u{1F467}"
    clusters(family).size.should eq(1)
    clusters(family).first.should eq(family)
  end

  it "keeps emoji modifiers (skin tones) with their base" do
    # Thumbs up + medium-light skin tone
    thumbs = "\u{1F44D}\u{1F3FC}"
    clusters(thumbs).should eq([thumbs])
  end

  it "pairs regional indicator symbols into flag sequences" do
    # US flag = U+1F1FA U+1F1F8
    flag_us = "\u{1F1FA}\u{1F1F8}"
    clusters(flag_us).should eq([flag_us])
  end

  it "splits four regional indicators into two flag pairs" do
    # USUS = two flags
    flags = "\u{1F1FA}\u{1F1F8}\u{1F1FA}\u{1F1F8}"
    result = clusters(flags)
    result.size.should eq(2)
    result[0].should eq("\u{1F1FA}\u{1F1F8}")
    result[1].should eq("\u{1F1FA}\u{1F1F8}")
  end

  it "keeps variation selectors with their base" do
    # Text presentation selector (VS15)
    text_heart = "\u2764\uFE0E"
    clusters(text_heart).should eq([text_heart])

    # Emoji presentation selector (VS16)
    emoji_heart = "\u2764\uFE0F"
    clusters(emoji_heart).should eq([emoji_heart])
  end

  it "handles mixed ASCII and emoji" do
    result = clusters("Hi\u{1F44B}!")
    result.should eq(["H", "i", "\u{1F44B}", "!"])
  end
end
