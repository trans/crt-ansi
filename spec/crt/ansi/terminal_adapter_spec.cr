require "../../spec_helper"

describe CRT::Ansi::TerminalAdapter do
  it "detects ghostty and applies hyperlink/osc overrides" do
    env = {
      "TERM"         => "xterm-256color",
      "TERM_PROGRAM" => "ghostty",
    } of String => String

    adapter = CRT::Ansi::TerminalAdapter.detect(env)
    adapter.kind.ghostty?.should be_true

    base = CRT::Ansi::Capabilities.new(hyperlinks: false, osc_terminator: CRT::Ansi::Capabilities::OscTerminator::ST)
    applied = adapter.apply(base)

    applied.hyperlinks.should be_true
    applied.osc_terminator.bel?.should be_true
  end
end
