require "../../spec_helper"

# Helper: create an Input reader from a byte sequence
private def input_from(*bytes : Int32) : CRT::Ansi::Input
  io = IO::Memory.new
  bytes.each { |b| io.write_byte(b.to_u8) }
  io.rewind
  CRT::Ansi::Input.new(io)
end

private def input_from(str : String) : CRT::Ansi::Input
  CRT::Ansi::Input.new(IO::Memory.new(str))
end

describe CRT::Ansi::Input do
  describe "printable ASCII" do
    it "reads a single character" do
      key = input_from("a").read_key
      key.should_not be_nil
      key = key.not_nil!
      key.code.should eq(CRT::Ansi::Key::Code::Char)
      key.char.should eq("a")
    end

    it "reads space" do
      key = input_from(" ").read_key.not_nil!
      key.char.should eq(" ")
    end
  end

  describe "control characters" do
    it "reads Enter (CR)" do
      key = input_from(0x0d).read_key.not_nil!
      key.code.should eq(CRT::Ansi::Key::Code::Enter)
    end

    it "reads Enter (LF)" do
      key = input_from(0x0a).read_key.not_nil!
      key.code.should eq(CRT::Ansi::Key::Code::Enter)
    end

    it "reads Tab" do
      key = input_from(0x09).read_key.not_nil!
      key.code.should eq(CRT::Ansi::Key::Code::Tab)
    end

    it "reads Backspace (0x7f)" do
      key = input_from(0x7f).read_key.not_nil!
      key.code.should eq(CRT::Ansi::Key::Code::Backspace)
    end

    it "reads Backspace (0x08)" do
      key = input_from(0x08).read_key.not_nil!
      key.code.should eq(CRT::Ansi::Key::Code::Backspace)
    end

    it "reads Ctrl+A" do
      key = input_from(0x01).read_key.not_nil!
      key.ctrl?.should be_true
      key.char.should eq("a")
    end

    it "reads Ctrl+C" do
      key = input_from(0x03).read_key.not_nil!
      key.ctrl?.should be_true
      key.char.should eq("c")
    end

    it "reads Ctrl+Z" do
      key = input_from(0x1a).read_key.not_nil!
      key.ctrl?.should be_true
      key.char.should eq("z")
    end
  end

  describe "bare Escape" do
    it "reads ESC alone as Escape key" do
      key = input_from(0x1b).read_key.not_nil!
      key.code.should eq(CRT::Ansi::Key::Code::Escape)
    end
  end

  describe "CSI sequences (ESC[...)" do
    it "reads arrow keys" do
      input_from("\e[A").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::Up)
      input_from("\e[B").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::Down)
      input_from("\e[C").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::Right)
      input_from("\e[D").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::Left)
    end

    it "reads Home and End" do
      input_from("\e[H").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::Home)
      input_from("\e[F").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::End)
    end

    it "reads tilde sequences" do
      input_from("\e[2~").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::Insert)
      input_from("\e[3~").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::Delete)
      input_from("\e[5~").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::PageUp)
      input_from("\e[6~").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::PageDown)
    end

    it "reads function keys via tilde" do
      input_from("\e[15~").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::F5)
      input_from("\e[17~").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::F6)
      input_from("\e[24~").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::F12)
    end

    it "reads function keys via CSI final bytes" do
      input_from("\e[P").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::F1)
      input_from("\e[Q").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::F2)
      input_from("\e[R").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::F3)
      input_from("\e[S").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::F4)
    end

    it "reads modified arrow keys" do
      # Shift+Up = ESC[1;2A
      key = input_from("\e[1;2A").read_key.not_nil!
      key.code.should eq(CRT::Ansi::Key::Code::Up)
      key.shift?.should be_true
      key.alt?.should be_false
      key.ctrl?.should be_false

      # Alt+Down = ESC[1;3B
      key = input_from("\e[1;3B").read_key.not_nil!
      key.code.should eq(CRT::Ansi::Key::Code::Down)
      key.alt?.should be_true

      # Ctrl+Right = ESC[1;5C
      key = input_from("\e[1;5C").read_key.not_nil!
      key.code.should eq(CRT::Ansi::Key::Code::Right)
      key.ctrl?.should be_true

      # Ctrl+Shift+Left = ESC[1;6D
      key = input_from("\e[1;6D").read_key.not_nil!
      key.code.should eq(CRT::Ansi::Key::Code::Left)
      key.shift?.should be_true
      key.ctrl?.should be_true
    end

    it "reads modified tilde sequences" do
      # Shift+Delete = ESC[3;2~
      key = input_from("\e[3;2~").read_key.not_nil!
      key.code.should eq(CRT::Ansi::Key::Code::Delete)
      key.shift?.should be_true

      # Ctrl+PageUp = ESC[5;5~
      key = input_from("\e[5;5~").read_key.not_nil!
      key.code.should eq(CRT::Ansi::Key::Code::PageUp)
      key.ctrl?.should be_true
    end
  end

  describe "SS3 sequences (ESC O...)" do
    it "reads SS3 arrow keys" do
      input_from("\eOA").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::Up)
      input_from("\eOB").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::Down)
      input_from("\eOC").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::Right)
      input_from("\eOD").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::Left)
    end

    it "reads SS3 function keys" do
      input_from("\eOP").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::F1)
      input_from("\eOQ").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::F2)
      input_from("\eOR").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::F3)
      input_from("\eOS").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::F4)
    end

    it "reads SS3 Home and End" do
      input_from("\eOH").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::Home)
      input_from("\eOF").read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::End)
    end
  end

  describe "UTF-8 input" do
    it "reads 2-byte UTF-8" do
      key = input_from("\u{00e9}").read_key.not_nil!  # é
      key.char.should eq("\u{00e9}")
    end

    it "reads 3-byte UTF-8" do
      key = input_from("\u{4e16}").read_key.not_nil!  # 世
      key.char.should eq("\u{4e16}")
    end

    it "reads 4-byte UTF-8 (emoji)" do
      key = input_from("\u{1f680}").read_key.not_nil!  # 🚀
      key.char.should eq("\u{1f680}")
    end
  end

  describe "sequential reads" do
    it "reads multiple keys in sequence" do
      input = input_from("abc")
      input.read_key.not_nil!.char.should eq("a")
      input.read_key.not_nil!.char.should eq("b")
      input.read_key.not_nil!.char.should eq("c")
      input.read_key.should be_nil
    end

    it "reads mixed keys and escape sequences" do
      input = input_from("x\e[Ay")
      input.read_key.not_nil!.char.should eq("x")
      input.read_key.not_nil!.code.should eq(CRT::Ansi::Key::Code::Up)
      input.read_key.not_nil!.char.should eq("y")
    end
  end

  describe "EOF" do
    it "returns nil on empty input" do
      input_from("").read_key.should be_nil
    end
  end
end
