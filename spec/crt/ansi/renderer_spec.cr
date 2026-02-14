require "../../spec_helper"

describe CRT::Ansi::Renderer do
  it "renders only diffs after initial frame" do
    io = IO::Memory.new
    renderer = CRT::Ansi::Renderer.new(io, 4, 1)

    renderer.back_buffer.write(0, 0, "AB")
    renderer.present
    first_frame = io.to_s
    first_frame.should contain("\e[1;1HAB")

    renderer.back_buffer.put(1, 0, "C")
    renderer.present

    second_frame = io.to_s.byte_slice(first_frame.bytesize, io.to_s.bytesize - first_frame.bytesize)
    second_frame.should eq("\e[1;2HC")
  end

  it "emits hyperlink open/close sequences when style changes" do
    caps = CRT::Ansi::Capabilities.new(
      hyperlinks: true,
      osc_terminator: CRT::Ansi::OscTerminator::ST
    )
    ctx = CRT::Ansi::Context.new(capabilities: caps)

    io = IO::Memory.new
    renderer = CRT::Ansi::Renderer.new(io, 1, 1, context: ctx)

    linked = CRT::Ansi::Style.default.with_hyperlink("https://example.com")
    renderer.back_buffer.put(0, 0, "X", linked)
    renderer.present
    first_frame = io.to_s
    first_frame.should contain("\e]8;;https://example.com\e\\")

    renderer.back_buffer.put(0, 0, "Y", CRT::Ansi::Style.default)
    renderer.present

    second_frame = io.to_s.byte_slice(first_frame.bytesize, io.to_s.bytesize - first_frame.bytesize)
    second_frame.should contain(CRT::Ansi::Hyperlink.close_sequence(CRT::Ansi::OscTerminator::ST))
  end

  it "suppresses hyperlink sequences when disabled by capabilities" do
    caps = CRT::Ansi::Capabilities.new(hyperlinks: false)
    ctx = CRT::Ansi::Context.new(capabilities: caps)

    io = IO::Memory.new
    renderer = CRT::Ansi::Renderer.new(io, 1, 1, context: ctx)
    linked = CRT::Ansi::Style.default.with_hyperlink("https://example.com")

    renderer.back_buffer.put(0, 0, "X", linked)
    renderer.present

    io.to_s.should_not contain("\e]8;")
  end

  it "returns output bytesize from present" do
    io = IO::Memory.new
    renderer = CRT::Ansi::Renderer.new(io, 3, 1)
    renderer.back_buffer.write(0, 0, "Hi")
    bytes = renderer.present
    bytes.should be > 0
  end

  it "returns 0 when nothing changed" do
    io = IO::Memory.new
    renderer = CRT::Ansi::Renderer.new(io, 3, 1)
    renderer.present  # first frame (blank → blank)
    bytes = renderer.present  # second frame, no changes
    bytes.should eq(0)
  end

  describe "#resize" do
    it "creates new buffers and triggers full redraw" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 3, 1)
      renderer.back_buffer.write(0, 0, "AB")
      renderer.present

      renderer.resize(5, 2)
      renderer.back_buffer.width.should eq(5)
      renderer.back_buffer.height.should eq(2)
      renderer.front_buffer.width.should eq(5)

      # After resize, writing and presenting should work
      renderer.back_buffer.write(0, 0, "Hello")
      bytes = renderer.present
      bytes.should be > 0
    end
  end

  describe "#force_full_redraw!" do
    it "causes next present to render all cells" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 3, 1)
      renderer.back_buffer.write(0, 0, "ABC")
      renderer.present
      first_size = io.to_s.bytesize

      # No changes to back buffer, but force full redraw
      renderer.force_full_redraw!
      renderer.present
      output = io.to_s.byte_slice(first_size, io.to_s.bytesize - first_size)
      # Full redraw should emit cursor move + content
      output.should contain("ABC")
    end
  end

  describe "#reset_terminal_state!" do
    it "emits SGR reset and flushes" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 3, 1)
      renderer.reset_terminal_state!
      io.to_s.should contain("\e[0m")
    end
  end

  describe "origin offset" do
    it "applies origin_x and origin_y to cursor positioning" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 3, 1, origin_x: 5, origin_y: 10)
      renderer.back_buffer.put(0, 0, "A")
      renderer.present

      # Cursor should be at origin: row 10, col 5
      io.to_s.should contain("\e[10;5H")
    end

    it "rejects origin less than 1" do
      io = IO::Memory.new
      expect_raises(ArgumentError) { CRT::Ansi::Renderer.new(io, 3, 1, origin_x: 0) }
      expect_raises(ArgumentError) { CRT::Ansi::Renderer.new(io, 3, 1, origin_y: 0) }
    end
  end

  describe "styled rendering" do
    it "emits SGR sequences for styled cells" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 3, 1)
      style = CRT::Ansi::Style.new(bold: true)
      renderer.back_buffer.write(0, 0, "Hi", style)
      renderer.present

      output = io.to_s
      output.should contain("\e[0;1m")  # bold SGR
      output.should contain("Hi")
    end
  end
end
