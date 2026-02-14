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

  it "detects 256color from TERM" do
    env = {
      "TERM" => "xterm-256color",
    } of String => String

    capabilities = CRT::Ansi::Capabilities.detect(env)
    capabilities.ansi256?.should be_true
  end

  it "respects NO_COLOR environment variable" do
    env = {
      "TERM"     => "xterm-256color",
      "NO_COLOR" => "",
    } of String => String

    capabilities = CRT::Ansi::Capabilities.detect(env)
    capabilities.color_support.none?.should be_true
  end

  it "respects CRT_ANSI_HYPERLINKS=off" do
    env = {
      "TERM"                => "xterm-256color",
      "CRT_ANSI_HYPERLINKS" => "off",
    } of String => String

    capabilities = CRT::Ansi::Capabilities.detect(env)
    capabilities.hyperlinks.should be_false
  end

  it "respects CRT_ANSI_OSC_TERMINATOR=bel" do
    env = {
      "TERM"                      => "xterm-256color",
      "CRT_ANSI_OSC_TERMINATOR"   => "bel",
    } of String => String

    capabilities = CRT::Ansi::Capabilities.detect(env)
    capabilities.osc_terminator.bel?.should be_true
  end

  it "defaults to ST osc terminator for non-ghostty" do
    env = {
      "TERM" => "xterm-256color",
    } of String => String

    capabilities = CRT::Ansi::Capabilities.detect(env)
    capabilities.osc_terminator.st?.should be_true
  end

  describe "#color?" do
    it "returns true when color support is not none" do
      CRT::Ansi::Capabilities.new(color_support: CRT::Ansi::Capabilities::ColorSupport::ANSI16).color?.should be_true
      CRT::Ansi::Capabilities.new(color_support: CRT::Ansi::Capabilities::ColorSupport::None).color?.should be_false
    end
  end

  describe "#copy_with" do
    it "creates a modified copy" do
      base = CRT::Ansi::Capabilities.new(bold: true, italic: false)
      modified = base.copy_with(italic: true)
      modified.bold.should be_true
      modified.italic.should be_true
    end
  end

  it "disables italic and blink on linux console" do
    env = {"TERM" => "linux"} of String => String
    capabilities = CRT::Ansi::Capabilities.detect(env)
    capabilities.italic.should be_false
    capabilities.blink.should be_false
  end

  it "detects empty TERM as dumb" do
    env = {"TERM" => ""} of String => String
    capabilities = CRT::Ansi::Capabilities.detect(env)
    capabilities.color_support.none?.should be_true
  end
end
