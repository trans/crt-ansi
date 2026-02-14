require "../../spec_helper"

describe CRT::Ansi::Mouse do
  describe "#initialize" do
    it "stores button, action, and position" do
      m = CRT::Ansi::Mouse.new(
        CRT::Ansi::Mouse::Button::Left,
        CRT::Ansi::Mouse::Action::Press,
        10, 20
      )
      m.button.should eq(CRT::Ansi::Mouse::Button::Left)
      m.action.should eq(CRT::Ansi::Mouse::Action::Press)
      m.x.should eq(10)
      m.y.should eq(20)
      m.shift?.should be_false
      m.alt?.should be_false
      m.ctrl?.should be_false
    end

    it "stores modifier flags" do
      m = CRT::Ansi::Mouse.new(
        CRT::Ansi::Mouse::Button::Right,
        CRT::Ansi::Mouse::Action::Release,
        5, 3,
        shift: true, alt: true, ctrl: true
      )
      m.shift?.should be_true
      m.alt?.should be_true
      m.ctrl?.should be_true
    end
  end

  describe "#==" do
    it "compares equal mice" do
      a = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left, CRT::Ansi::Mouse::Action::Press, 1, 2)
      b = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left, CRT::Ansi::Mouse::Action::Press, 1, 2)
      a.should eq(b)
    end

    it "detects inequality" do
      a = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left, CRT::Ansi::Mouse::Action::Press, 1, 2)
      b = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Right, CRT::Ansi::Mouse::Action::Press, 1, 2)
      a.should_not eq(b)
    end
  end

  describe "#to_s" do
    it "formats a basic mouse event" do
      m = CRT::Ansi::Mouse.new(CRT::Ansi::Mouse::Button::Left, CRT::Ansi::Mouse::Action::Press, 10, 5)
      m.to_s.should eq("Left Press (10,5)")
    end

    it "includes modifiers" do
      m = CRT::Ansi::Mouse.new(
        CRT::Ansi::Mouse::Button::Right,
        CRT::Ansi::Mouse::Action::Release,
        3, 7,
        ctrl: true, alt: true, shift: true
      )
      m.to_s.should eq("Ctrl+Alt+Shift+Right Release (3,7)")
    end
  end
end
