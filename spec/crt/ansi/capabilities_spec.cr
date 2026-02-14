require "../../spec_helper"

describe CRT::Ansi::Capabilities do
  it "detects dumb terminals as low capability" do
    env = {"TERM" => "dumb"} of String => String
    capabilities = CRT::Ansi::Capabilities.detect(env)

    capabilities.color_support.none?.should be_true
    capabilities.hyperlinks.should be_false
    capabilities.cursor_addressing.should be_false
  end

  it "detects truecolor and ghostty osc preference" do
    env = {
      "TERM"         => "xterm-256color",
      "COLORTERM"    => "truecolor",
      "TERM_PROGRAM" => "ghostty",
    } of String => String

    capabilities = CRT::Ansi::Capabilities.detect(env)
    capabilities.truecolor?.should be_true
    capabilities.osc_terminator.bel?.should be_true
  end
end
