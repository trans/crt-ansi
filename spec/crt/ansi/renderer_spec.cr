require "../../spec_helper"

describe CRT::Ansi::Renderer do
  it "renders only diffs after initial frame" do
    io = IO::Memory.new
    renderer = CRT::Ansi::Renderer.new(io, 4, 1)

    renderer.write(0, 0, "AB")
    renderer.present
    first_frame = io.to_s
    first_frame.should contain("\e[1;1HAB")

    renderer.put(1, 0, "C")
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
    renderer.put(0, 0, "X", linked)
    renderer.present
    first_frame = io.to_s
    first_frame.should contain("\e]8;;https://example.com\e\\")

    renderer.put(0, 0, "Y", CRT::Ansi::Style.default)
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

    renderer.put(0, 0, "X", linked)
    renderer.present

    io.to_s.should_not contain("\e]8;")
  end

  it "returns output bytesize from present" do
    io = IO::Memory.new
    renderer = CRT::Ansi::Renderer.new(io, 3, 1)
    renderer.write(0, 0, "Hi")
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

  describe "#width / #height" do
    it "exposes buffer dimensions" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 40, 10)
      renderer.width.should eq(40)
      renderer.height.should eq(10)
    end
  end

  describe "drawing delegates" do
    it "delegates put/write/clear/cell to the back buffer" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 5, 1)

      renderer.write(0, 0, "Hi")
      renderer.cell(0, 0).grapheme.should eq("H")
      renderer.cell(1, 0).grapheme.should eq("i")

      renderer.put(2, 0, "!")
      renderer.cell(2, 0).grapheme.should eq("!")

      renderer.clear
      renderer.cell(0, 0).blank?.should be_true
    end
  end

  describe "#resize" do
    it "creates new buffers and triggers full redraw" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 3, 1)
      renderer.write(0, 0, "AB")
      renderer.present

      renderer.resize(5, 2)
      renderer.width.should eq(5)
      renderer.height.should eq(2)

      renderer.write(0, 0, "Hello")
      bytes = renderer.present
      bytes.should be > 0
    end
  end

  describe "#force_full_redraw!" do
    it "causes next present to render all cells" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 3, 1)
      renderer.write(0, 0, "ABC")
      renderer.present
      first_size = io.to_s.bytesize

      # No changes to back buffer, but force full redraw
      renderer.force_full_redraw!
      renderer.present
      output = io.to_s.byte_slice(first_size, io.to_s.bytesize - first_size)
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
      renderer.put(0, 0, "A")
      renderer.present

      io.to_s.should contain("\e[10;5H")
    end

    it "rejects origin less than 1" do
      io = IO::Memory.new
      expect_raises(ArgumentError) { CRT::Ansi::Renderer.new(io, 3, 1, origin_x: 0) }
      expect_raises(ArgumentError) { CRT::Ansi::Renderer.new(io, 3, 1, origin_y: 0) }
    end
  end

  describe "#box" do
    it "draws a box with corners and edges" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 5, 3)
      renderer.box(0, 0, w: 5, h: 3)

      renderer.cell(0, 0).grapheme.should eq("┌")
      renderer.cell(4, 0).grapheme.should eq("┐")
      renderer.cell(0, 2).grapheme.should eq("└")
      renderer.cell(4, 2).grapheme.should eq("┘")
      renderer.cell(1, 0).grapheme.should eq("─")
      renderer.cell(0, 1).grapheme.should eq("│")
    end

    it "draws a horizontal line when h is 0" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 5, 1)
      renderer.box(0, 0, w: 5)

      5.times { |i| renderer.cell(i, 0).grapheme.should eq("─") }
    end

    it "draws a vertical line when w is 0" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 1, 5)
      renderer.box(0, 0, h: 5)

      5.times { |j| renderer.cell(0, j).grapheme.should eq("│") }
    end

    it "fills the interior with spaces when a Style is given" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 5, 3)
      fill_style = CRT::Ansi::Style.new(bg: CRT::Ansi::Color.indexed(1))
      renderer.box(0, 0, w: 5, h: 3, fill: fill_style)

      renderer.cell(1, 1).grapheme.should eq(" ")
      renderer.cell(1, 1).style.should eq(fill_style)
      renderer.cell(2, 1).style.should eq(fill_style)
      renderer.cell(3, 1).style.should eq(fill_style)
    end

    it "fills the interior with a custom character" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 5, 3)
      renderer.box(0, 0, w: 5, h: 3, fill: CRT::Ansi::Style::Char.new('·'))

      renderer.cell(1, 1).grapheme.should eq("·")
      renderer.cell(2, 1).grapheme.should eq("·")
      renderer.cell(3, 1).grapheme.should eq("·")
    end

    it "leaves interior untouched without fill" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 5, 3)
      renderer.box(0, 0, w: 5, h: 3)

      # Interior should still be blank (default)
      renderer.cell(1, 1).blank?.should be_true
    end

    it "supports different border styles" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 4, 3)
      renderer.box(0, 0, w: 4, h: 3, border: CRT::Ansi::Border::Double)

      renderer.cell(0, 0).grapheme.should eq("╔")
      renderer.cell(1, 0).grapheme.should eq("═")
      renderer.cell(0, 1).grapheme.should eq("║")
    end

    it "supports rounded corners" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 4, 3)
      renderer.box(0, 0, w: 4, h: 3, border: CRT::Ansi::Border::Rounded)

      renderer.cell(0, 0).grapheme.should eq("╭")
      renderer.cell(3, 0).grapheme.should eq("╮")
      renderer.cell(0, 2).grapheme.should eq("╰")
      renderer.cell(3, 2).grapheme.should eq("╯")
    end

    it "does nothing when both w and h are 0" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 3, 3)
      renderer.box(0, 0, w: 0, h: 0)
      renderer.cell(0, 0).blank?.should be_true
    end
  end

  describe "#cursor_to" do
    it "moves cursor to the requested position after present" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 10, 5)
      renderer.write(0, 0, "Hello")
      renderer.cursor_to(3, 2)
      renderer.present

      # origin is 1,1 so buffer (3,2) → terminal (4,3)
      output = io.to_s
      output.should match(/\e\[3;4H\z/)
    end

    it "does not emit cursor move when no position requested" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 5, 1)
      renderer.write(0, 0, "AB")
      renderer.present

      # Output should NOT end with a cursor-move after the content
      output = io.to_s
      output.should_not match(/\e\[\d+;\d+H\z/)
    end

    it "persists cursor position across presents" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 5, 3)
      renderer.cursor_to(1, 1)

      renderer.write(0, 0, "A")
      renderer.present
      first_size = io.to_s.bytesize

      # Change something to trigger a diff render
      renderer.write(0, 0, "B")
      renderer.present

      output = io.to_s.byte_slice(first_size, io.to_s.bytesize - first_size)
      # Should end with cursor at (1,1) → terminal (2,2)
      output.should match(/\e\[2;2H\z/)
    end

    it "clears cursor request with (-1, -1)" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 5, 1)
      renderer.cursor_to(2, 0)
      renderer.cursor_to(-1, -1)
      renderer.write(0, 0, "AB")
      renderer.present

      output = io.to_s
      output.should_not match(/\e\[\d+;\d+H\z/)
    end
  end

  describe "styled rendering" do
    it "emits SGR sequences for styled cells" do
      io = IO::Memory.new
      renderer = CRT::Ansi::Renderer.new(io, 3, 1)
      style = CRT::Ansi::Style.new(bold: true)
      renderer.write(0, 0, "Hi", style)
      renderer.present

      output = io.to_s
      output.should contain("\e[0;1m")
      output.should contain("Hi")
    end
  end
end
