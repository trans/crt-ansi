require "../../spec_helper"

describe CRT::Ansi::Screen do
  describe "#initialize" do
    it "creates a screen with default 80x24 for non-TTY IO" do
      io = IO::Memory.new
      screen = CRT::Ansi::Screen.new(io, alt_screen: false, raw_mode: false, hide_cursor: false)
      screen.width.should eq(80)
      screen.height.should eq(24)
      screen.running?.should be_false
    end

    it "accepts a custom context" do
      io = IO::Memory.new
      ctx = CRT::Ansi::Context.new
      screen = CRT::Ansi::Screen.new(io, alt_screen: false, raw_mode: false, hide_cursor: false, context: ctx)
      screen.render.context.should eq(ctx)
    end
  end

  describe "#start / #stop" do
    it "enters and exits alt screen" do
      io = IO::Memory.new
      screen = CRT::Ansi::Screen.new(io, alt_screen: true, raw_mode: false, hide_cursor: false)
      screen.start
      screen.running?.should be_true
      screen.alt_screen?.should be_true
      io.to_s.should contain("\e[?1049h")

      screen.stop
      screen.running?.should be_false
      screen.alt_screen?.should be_false
      io.to_s.should contain("\e[?1049l")
    end

    it "hides and shows cursor" do
      io = IO::Memory.new
      screen = CRT::Ansi::Screen.new(io, alt_screen: false, raw_mode: false, hide_cursor: true)
      screen.start
      screen.cursor_hidden?.should be_true
      io.to_s.should contain("\e[?25l")

      screen.stop
      screen.cursor_hidden?.should be_false
      io.to_s.should contain("\e[?25h")
    end

    it "skips raw mode for non-TTY IO" do
      io = IO::Memory.new
      screen = CRT::Ansi::Screen.new(io, alt_screen: false, raw_mode: true, hide_cursor: false)
      screen.start
      screen.raw_mode?.should be_false
    end

    it "is idempotent on double start" do
      io = IO::Memory.new
      screen = CRT::Ansi::Screen.new(io, alt_screen: true, raw_mode: false, hide_cursor: false)
      screen.start
      first_output = io.to_s.dup
      screen.start  # second call should be no-op
      io.to_s.should eq(first_output)
    end

    it "is idempotent on double stop" do
      io = IO::Memory.new
      screen = CRT::Ansi::Screen.new(io, alt_screen: false, raw_mode: false, hide_cursor: false)
      screen.start
      screen.stop
      first_output = io.to_s.dup
      screen.stop  # second call should be no-op
      io.to_s.should eq(first_output)
    end
  end

  describe ".open" do
    it "yields a started screen and stops on block exit" do
      io = IO::Memory.new
      was_running = false

      CRT::Ansi::Screen.open(io, alt_screen: true, raw_mode: false, hide_cursor: false) do |screen|
        was_running = screen.running?
      end

      was_running.should be_true
      output = io.to_s
      output.should contain("\e[?1049h")  # entered alt screen
      output.should contain("\e[?1049l")  # exited alt screen
    end

    it "stops screen even on exception" do
      io = IO::Memory.new
      begin
        CRT::Ansi::Screen.open(io, alt_screen: true, raw_mode: false, hide_cursor: false) do |screen|
          raise "test error"
        end
      rescue Exception
      end

      io.to_s.should contain("\e[?1049l")
    end
  end

  describe "#cursor" do
    it "toggles cursor visibility" do
      io = IO::Memory.new
      screen = CRT::Ansi::Screen.new(io, alt_screen: false, raw_mode: false, hide_cursor: false)
      screen.start

      screen.cursor(false)
      screen.cursor_hidden?.should be_true
      io.to_s.should contain("\e[?25l")

      screen.cursor(true)
      screen.cursor_hidden?.should be_false
      io.to_s.should contain("\e[?25h")
    end
  end

  describe "#resize" do
    it "updates renderer dimensions" do
      io = IO::Memory.new
      screen = CRT::Ansi::Screen.new(io, alt_screen: false, raw_mode: false, hide_cursor: false)
      screen.width.should eq(80)
      screen.height.should eq(24)

      screen.resize(120, 40)
      screen.width.should eq(120)
      screen.height.should eq(40)
    end
  end

  describe "drawing delegates" do
    it "delegates put/write/clear/cell to the renderer" do
      io = IO::Memory.new
      screen = CRT::Ansi::Screen.new(io, alt_screen: false, raw_mode: false, hide_cursor: false)

      screen.write(0, 0, "Hi")
      screen.cell(0, 0).grapheme.should eq("H")
      screen.cell(1, 0).grapheme.should eq("i")

      screen.put(2, 0, "!")
      screen.cell(2, 0).grapheme.should eq("!")

      screen.clear
      screen.cell(0, 0).blank?.should be_true
    end
  end

  describe "#present" do
    it "renders to the IO" do
      io = IO::Memory.new
      screen = CRT::Ansi::Screen.new(io, alt_screen: false, raw_mode: false, hide_cursor: false)
      screen.write(0, 0, "Hello")
      bytes = screen.present
      bytes.should be > 0
      io.to_s.should contain("Hello")
    end
  end

  describe "#on_resize" do
    it "stores a resize handler" do
      io = IO::Memory.new
      screen = CRT::Ansi::Screen.new(io, alt_screen: false, raw_mode: false, hide_cursor: false)
      called = false
      screen.on_resize { |w, h| called = true }
      # Can't easily trigger SIGWINCH in specs, but at least verify it compiles
      called.should be_false
    end
  end
end
