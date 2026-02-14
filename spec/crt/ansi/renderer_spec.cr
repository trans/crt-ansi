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
end
