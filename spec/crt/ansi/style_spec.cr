require "../../spec_helper"

describe CRT::Ansi::Style do
  it "removes unsupported attributes and colors via capabilities" do
    style = CRT::Ansi::Style.new(
      fg: CRT::Ansi::Color.rgb(255, 0, 0),
      bold: true,
      italic: true
    )
    capabilities = CRT::Ansi::Capabilities.new(
      color_support: CRT::Ansi::Capabilities::ColorSupport::None,
      bold: false,
      italic: false
    )

    sequence = String.build do |io|
      style.append_sgr(io, capabilities)
    end

    sequence.should eq("\e[0m")
  end
end
