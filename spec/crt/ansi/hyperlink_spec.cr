require "../../spec_helper"

describe CRT::Ansi::Hyperlink do
  it "supports BEL terminator mode" do
    link = CRT::Ansi::Hyperlink.new("https://example.com")

    link.open_sequence(CRT::Ansi::OscTerminator::BEL).should eq("\e]8;;https://example.com\a")
    CRT::Ansi::Hyperlink.close_sequence(CRT::Ansi::OscTerminator::BEL).should eq("\e]8;;\a")
  end

  it "defaults to ST terminator" do
    link = CRT::Ansi::Hyperlink.new("https://example.com")

    link.open_sequence(CRT::Ansi::OscTerminator::ST).should eq("\e]8;;https://example.com\e\\")
    CRT::Ansi::Hyperlink.close_sequence(CRT::Ansi::OscTerminator::ST).should eq("\e]8;;\e\\")
  end

  it "includes id parameter when provided" do
    link = CRT::Ansi::Hyperlink.new("https://example.com", id: "link-42")
    seq = link.open_sequence(CRT::Ansi::OscTerminator::ST)
    seq.should contain("id=link-42")
    seq.should contain("https://example.com")
  end

  it "sanitizes semicolons and colons from id" do
    link = CRT::Ansi::Hyperlink.new("https://example.com", id: "a;b:c")
    seq = link.open_sequence(CRT::Ansi::OscTerminator::ST)
    seq.should contain("id=abc")
    seq.should_not contain(";b")
    seq.should_not contain(":c")
  end

  it "rejects empty URIs" do
    expect_raises(ArgumentError) { CRT::Ansi::Hyperlink.new("") }
  end

  it "exposes uri and id getters" do
    link = CRT::Ansi::Hyperlink.new("https://example.com", id: "test")
    link.uri.should eq("https://example.com")
    link.id.should eq("test")
  end

  it "allows nil id" do
    link = CRT::Ansi::Hyperlink.new("https://example.com")
    link.id.should be_nil
  end
end
