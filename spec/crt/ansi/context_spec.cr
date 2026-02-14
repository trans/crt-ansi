require "../../spec_helper"

describe CRT::Ansi::Context do
  it "detects terminal from environment" do
    env = {
      "TERM"         => "xterm-256color",
      "TERM_PROGRAM" => "ghostty",
    } of String => String

    ctx = CRT::Ansi::Context.detect(env, IO::Memory.new)
    ctx.terminal_adapter.kind.ghostty?.should be_true
    ctx.capabilities.osc_terminator.bel?.should be_true
    ctx.osc_terminator.bel?.should be_true
  end

  it "derives osc_terminator from capabilities" do
    caps = CRT::Ansi::Capabilities.new(osc_terminator: CRT::Ansi::OscTerminator::BEL)
    ctx = CRT::Ansi::Context.new(capabilities: caps)
    ctx.osc_terminator.bel?.should be_true
  end

  it "uses default values when not detecting" do
    ctx = CRT::Ansi::Context.new
    ctx.capabilities.color_support.ansi256?.should be_true
    ctx.terminal_adapter.kind.unknown?.should be_true
  end
end
