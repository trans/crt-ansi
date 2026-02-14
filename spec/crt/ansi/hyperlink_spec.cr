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
end
