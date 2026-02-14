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

  it "detects ghostty via GHOSTTY_RESOURCES_DIR" do
    env = {
      "TERM"                  => "xterm-256color",
      "GHOSTTY_RESOURCES_DIR" => "/usr/share/ghostty",
    } of String => String

    adapter = CRT::Ansi::TerminalAdapter.detect(env)
    adapter.kind.ghostty?.should be_true
  end

  it "detects kitty via KITTY_WINDOW_ID" do
    env = {
      "TERM"           => "xterm-kitty",
      "KITTY_WINDOW_ID" => "1",
    } of String => String

    adapter = CRT::Ansi::TerminalAdapter.detect(env)
    adapter.kind.kitty?.should be_true
    adapter.apply(CRT::Ansi::Capabilities.new(hyperlinks: false)).hyperlinks.should be_true
  end

  it "detects WezTerm" do
    env = {
      "TERM"         => "xterm-256color",
      "TERM_PROGRAM" => "WezTerm",
    } of String => String

    adapter = CRT::Ansi::TerminalAdapter.detect(env)
    adapter.kind.wez_term?.should be_true
  end

  it "detects iTerm" do
    env = {
      "TERM"         => "xterm-256color",
      "TERM_PROGRAM" => "iTerm.app",
    } of String => String

    adapter = CRT::Ansi::TerminalAdapter.detect(env)
    adapter.kind.i_term?.should be_true
  end

  it "detects VTE via VTE_VERSION" do
    env = {
      "TERM"        => "xterm-256color",
      "VTE_VERSION" => "7200",
    } of String => String

    adapter = CRT::Ansi::TerminalAdapter.detect(env)
    adapter.kind.vte?.should be_true
  end

  it "falls back to Unknown for unrecognized terminals" do
    env = {
      "TERM" => "xterm-256color",
    } of String => String

    adapter = CRT::Ansi::TerminalAdapter.detect(env)
    adapter.kind.unknown?.should be_true
  end

  it "does not modify capabilities for unknown terminal" do
    env = {"TERM" => "xterm"} of String => String
    adapter = CRT::Ansi::TerminalAdapter.detect(env)
    base = CRT::Ansi::Capabilities.new(hyperlinks: false)
    applied = adapter.apply(base)
    applied.hyperlinks.should be_false
  end

  it "provides width_resolver and grapheme_filter" do
    adapter = CRT::Ansi::TerminalAdapter.new
    adapter.width_resolver.call("A").should eq(1)
    adapter.grapheme_filter.call("test").should eq("test")
  end
end
