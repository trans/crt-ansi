require "../../spec_helper"

describe CRT::Ansi::Style do
  describe ".default" do
    it "has no attributes or colors set" do
      style = CRT::Ansi::Style.default
      style.bold.should be_false
      style.italic.should be_false
      style.fg.default?.should be_true
      style.bg.default?.should be_true
      style.hyperlink.should be_nil
    end
  end

  describe "#append_sgr" do
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

    it "emits all supported attributes" do
      style = CRT::Ansi::Style.new(
        bold: true, dim: true, italic: true,
        underline: true, blink: true, inverse: true,
        strikethrough: true
      )
      caps = CRT::Ansi::Capabilities.new

      sgr = String.build { |io| style.append_sgr(io, caps) }
      sgr.should contain(";1")   # bold
      sgr.should contain(";2")   # dim
      sgr.should contain(";3")   # italic
      sgr.should contain(";4")   # underline
      sgr.should contain(";5")   # blink
      sgr.should contain(";7")   # inverse
      sgr.should contain(";9")   # strikethrough
    end

    it "includes foreground and background color codes" do
      style = CRT::Ansi::Style.new(
        fg: CRT::Ansi::Color.rgb(255, 0, 0),
        bg: CRT::Ansi::Color.rgb(0, 0, 255)
      )
      caps = CRT::Ansi::Capabilities.new(
        color_support: CRT::Ansi::Capabilities::ColorSupport::Truecolor
      )

      sgr = String.build { |io| style.append_sgr(io, caps) }
      sgr.should contain("38;2;255;0;0")
      sgr.should contain("48;2;0;0;255")
    end

    it "selectively disables unsupported attributes" do
      style = CRT::Ansi::Style.new(bold: true, italic: true)
      caps = CRT::Ansi::Capabilities.new(bold: true, italic: false)

      sgr = String.build { |io| style.append_sgr(io, caps) }
      sgr.should contain(";1")    # bold present
      sgr.should_not contain(";3") # italic absent
    end
  end

  describe "#merge" do
    it "OR's boolean attributes" do
      base = CRT::Ansi::Style.new(bold: true)
      other = CRT::Ansi::Style.new(underline: true)
      merged = base.merge(other)
      merged.bold.should be_true
      merged.underline.should be_true
    end

    it "overrides non-default colors" do
      base = CRT::Ansi::Style.new(fg: CRT::Ansi::Color.indexed(1))
      other = CRT::Ansi::Style.new(fg: CRT::Ansi::Color.indexed(2))
      merged = base.merge(other)
      merged.fg.should eq(CRT::Ansi::Color.indexed(2))
    end

    it "preserves base color when other is default" do
      base = CRT::Ansi::Style.new(fg: CRT::Ansi::Color.indexed(1))
      other = CRT::Ansi::Style.default
      merged = base.merge(other)
      merged.fg.should eq(CRT::Ansi::Color.indexed(1))
    end

    it "preserves base hyperlink when other has none" do
      base = CRT::Ansi::Style.default.with_hyperlink("https://example.com")
      other = CRT::Ansi::Style.new(bold: true)
      merged = base.merge(other)
      merged.hyperlink.should_not be_nil
      merged.bold.should be_true
    end
  end

  describe "#with_fg" do
    it "returns a new style with the given foreground" do
      base = CRT::Ansi::Style.default
      red = base.with_fg(CRT::Ansi::Color.rgb(255, 0, 0))
      red.fg.red.should eq(255)
      red.bg.default?.should be_true
      base.fg.default?.should be_true
    end
  end

  describe "#with_bg" do
    it "returns a new style with the given background" do
      base = CRT::Ansi::Style.default
      blue = base.with_bg(CRT::Ansi::Color.rgb(0, 0, 255))
      blue.bg.blue.should eq(255)
      base.bg.default?.should be_true
    end
  end

  describe "#with_hyperlink / #without_hyperlink" do
    it "attaches and detaches hyperlink" do
      base = CRT::Ansi::Style.default
      linked = base.with_hyperlink("https://example.com", "id-1")
      linked.hyperlink.should_not be_nil
      linked.hyperlink.not_nil!.uri.should eq("https://example.com")

      plain = linked.without_hyperlink
      plain.hyperlink.should be_nil
    end
  end
end
