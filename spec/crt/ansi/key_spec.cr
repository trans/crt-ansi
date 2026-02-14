require "../../spec_helper"

describe CRT::Ansi::Key do
  describe ".char" do
    it "creates a character key from Char" do
      key = CRT::Ansi::Key.char('a')
      key.code.should eq(CRT::Ansi::Key::Code::Char)
      key.char.should eq("a")
      key.shift?.should be_false
      key.alt?.should be_false
      key.ctrl?.should be_false
    end

    it "creates a character key from String" do
      key = CRT::Ansi::Key.char("z")
      key.char.should eq("z")
      key.char?.should be_true
    end

    it "creates a key with modifiers" do
      key = CRT::Ansi::Key.char('x', shift: true, alt: true)
      key.shift?.should be_true
      key.alt?.should be_true
      key.ctrl?.should be_false
    end
  end

  describe ".ctrl" do
    it "creates a ctrl+key" do
      key = CRT::Ansi::Key.ctrl('c')
      key.char.should eq("c")
      key.ctrl?.should be_true
    end
  end

  describe "#==" do
    it "compares keys by code, char, and modifiers" do
      a = CRT::Ansi::Key.char('a')
      b = CRT::Ansi::Key.char('a')
      c = CRT::Ansi::Key.char('b')
      a.should eq(b)
      a.should_not eq(c)
    end

    it "distinguishes modifiers" do
      plain = CRT::Ansi::Key.char('a')
      ctrl = CRT::Ansi::Key.char('a', ctrl: true)
      plain.should_not eq(ctrl)
    end
  end

  describe "#to_s" do
    it "formats character keys" do
      CRT::Ansi::Key.char('a').to_s.should eq("a")
    end

    it "formats modified keys" do
      CRT::Ansi::Key.char('c', ctrl: true).to_s.should eq("Ctrl+c")
      CRT::Ansi::Key.char('x', alt: true, shift: true).to_s.should eq("Alt+Shift+x")
    end

    it "formats special keys" do
      CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Enter).to_s.should eq("Enter")
      CRT::Ansi::Key.new(CRT::Ansi::Key::Code::F1).to_s.should eq("F1")
      CRT::Ansi::Key.new(CRT::Ansi::Key::Code::Up, shift: true).to_s.should eq("Shift+Up")
    end
  end
end
