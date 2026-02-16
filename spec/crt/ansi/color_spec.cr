require "../../spec_helper"

describe CRT::Ansi::Color do
  describe ".default" do
    it "is the default mode" do
      color = CRT::Ansi::Color.default
      color.default?.should be_true
    end
  end

  describe ".indexed" do
    it "creates indexed colors in 0..255" do
      color = CRT::Ansi::Color.indexed(42)
      color.mode.indexed?.should be_true
      color.index.should eq(42)
    end

    it "rejects out-of-range indices" do
      expect_raises(ArgumentError) { CRT::Ansi::Color.indexed(256) }
      expect_raises(ArgumentError) { CRT::Ansi::Color.indexed(-1) }
    end
  end

  describe ".rgb" do
    it "creates RGB colors" do
      color = CRT::Ansi::Color.rgb(128, 64, 32)
      color.mode.rgb?.should be_true
      color.red.should eq(128)
      color.green.should eq(64)
      color.blue.should eq(32)
    end

    it "rejects out-of-range channels" do
      expect_raises(ArgumentError) { CRT::Ansi::Color.rgb(256, 0, 0) }
      expect_raises(ArgumentError) { CRT::Ansi::Color.rgb(0, -1, 0) }
      expect_raises(ArgumentError) { CRT::Ansi::Color.rgb(0, 0, 300) }
    end
  end

  describe "#append_fg_sgr" do
    caps_truecolor = CRT::Ansi::Capabilities.new(color_support: CRT::Ansi::Capabilities::ColorSupport::Truecolor)
    caps_256 = CRT::Ansi::Capabilities.new(color_support: CRT::Ansi::Capabilities::ColorSupport::ANSI256)
    caps_16 = CRT::Ansi::Capabilities.new(color_support: CRT::Ansi::Capabilities::ColorSupport::ANSI16)
    caps_none = CRT::Ansi::Capabilities.new(color_support: CRT::Ansi::Capabilities::ColorSupport::None)

    it "emits RGB SGR in truecolor mode" do
      color = CRT::Ansi::Color.rgb(255, 128, 0)
      sgr = String.build { |io| color.append_fg_sgr(io, caps_truecolor) }
      sgr.should eq("38;2;255;128;0")
    end

    it "emits indexed SGR in truecolor mode" do
      color = CRT::Ansi::Color.indexed(196)
      sgr = String.build { |io| color.append_fg_sgr(io, caps_truecolor) }
      sgr.should eq("38;5;196")
    end

    it "downsamples RGB to 256 in ansi256 mode" do
      color = CRT::Ansi::Color.rgb(255, 0, 0)
      sgr = String.build { |io| color.append_fg_sgr(io, caps_256) }
      sgr.should start_with("38;5;")
    end

    it "downsamples to ansi16 codes" do
      color = CRT::Ansi::Color.rgb(255, 0, 0)
      sgr = String.build { |io| color.append_fg_sgr(io, caps_16) }
      # ansi16 fg codes: 30-37, 90-97
      sgr.to_i.should be >= 30
    end

    it "emits default (39) when color support is none" do
      color = CRT::Ansi::Color.rgb(255, 0, 0)
      sgr = String.build { |io| color.append_fg_sgr(io, caps_none) }
      sgr.should eq("39")
    end

    it "emits default (39) for default color" do
      color = CRT::Ansi::Color.default
      sgr = String.build { |io| color.append_fg_sgr(io, caps_truecolor) }
      sgr.should eq("39")
    end
  end

  describe "#append_bg_sgr" do
    caps_truecolor = CRT::Ansi::Capabilities.new(color_support: CRT::Ansi::Capabilities::ColorSupport::Truecolor)
    caps_none = CRT::Ansi::Capabilities.new(color_support: CRT::Ansi::Capabilities::ColorSupport::None)

    it "emits RGB background SGR" do
      color = CRT::Ansi::Color.rgb(0, 128, 255)
      sgr = String.build { |io| color.append_bg_sgr(io, caps_truecolor) }
      sgr.should eq("48;2;0;128;255")
    end

    it "emits default (49) when color support is none" do
      color = CRT::Ansi::Color.rgb(0, 128, 255)
      sgr = String.build { |io| color.append_bg_sgr(io, caps_none) }
      sgr.should eq("49")
    end
  end

  describe ".lerp" do
    it "returns a at t=0" do
      a = CRT::Ansi::Color.rgb(0, 0, 0)
      b = CRT::Ansi::Color.rgb(255, 255, 255)
      CRT::Ansi::Color.lerp(a, b, 0.0).should eq(a)
    end

    it "returns b at t=1" do
      a = CRT::Ansi::Color.rgb(0, 0, 0)
      b = CRT::Ansi::Color.rgb(255, 255, 255)
      CRT::Ansi::Color.lerp(a, b, 1.0).should eq(b)
    end

    it "returns midpoint at t=0.5" do
      a = CRT::Ansi::Color.rgb(0, 0, 0)
      b = CRT::Ansi::Color.rgb(200, 100, 50)
      result = CRT::Ansi::Color.lerp(a, b, 0.5)
      result.red.should eq(100)
      result.green.should eq(50)
      result.blue.should eq(25)
    end

    it "treats default colors as black" do
      d = CRT::Ansi::Color.default
      b = CRT::Ansi::Color.rgb(100, 100, 100)
      result = CRT::Ansi::Color.lerp(d, b, 0.5)
      result.red.should eq(50)
    end

    it "clamps to 0..255" do
      a = CRT::Ansi::Color.rgb(200, 200, 200)
      b = CRT::Ansi::Color.rgb(255, 255, 255)
      result = CRT::Ansi::Color.lerp(a, b, 2.0)
      result.red.should eq(255)
    end
  end

  describe "RGB downsampling" do
    caps_256 = CRT::Ansi::Capabilities.new(color_support: CRT::Ansi::Capabilities::ColorSupport::ANSI256)
    caps_16 = CRT::Ansi::Capabilities.new(color_support: CRT::Ansi::Capabilities::ColorSupport::ANSI16)

    it "maps pure black to index 16 in 256-color mode" do
      color = CRT::Ansi::Color.rgb(0, 0, 0)
      sgr = String.build { |io| color.append_fg_sgr(io, caps_256) }
      sgr.should eq("38;5;16")
    end

    it "maps pure white to index 231 in 256-color mode" do
      color = CRT::Ansi::Color.rgb(255, 255, 255)
      sgr = String.build { |io| color.append_fg_sgr(io, caps_256) }
      sgr.should eq("38;5;231")
    end

    it "maps pure red to bright red (91) in 16-color fg mode" do
      color = CRT::Ansi::Color.rgb(255, 0, 0)
      sgr = String.build { |io| color.append_fg_sgr(io, caps_16) }
      # index 9 → 90 + (9-8) = 91
      sgr.should eq("91")
    end

    it "maps black to code 30 in 16-color fg mode" do
      color = CRT::Ansi::Color.rgb(0, 0, 0)
      sgr = String.build { |io| color.append_fg_sgr(io, caps_16) }
      # index 0 → 30
      sgr.should eq("30")
    end

    it "maps white to bright white (97) in 16-color fg mode" do
      color = CRT::Ansi::Color.rgb(255, 255, 255)
      sgr = String.build { |io| color.append_fg_sgr(io, caps_16) }
      # index 15 → 90 + (15-8) = 97
      sgr.should eq("97")
    end

    it "maps indexed colors to 16-color bg codes" do
      color = CRT::Ansi::Color.indexed(0)  # black
      sgr = String.build { |io| color.append_bg_sgr(io, caps_16) }
      sgr.should eq("40")
    end
  end
end
