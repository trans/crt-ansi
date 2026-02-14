require "../../spec_helper"

describe CRT::Ansi::Border do
  describe "#chars" do
    it "returns single line-drawing characters" do
      hz, vt, tl, tr, bl, br = CRT::Ansi::Border::Single.chars
      hz.should eq("─")
      vt.should eq("│")
      tl.should eq("┌")
      tr.should eq("┐")
      bl.should eq("└")
      br.should eq("┘")
    end

    it "returns double line-drawing characters" do
      hz, vt, tl, tr, bl, br = CRT::Ansi::Border::Double.chars
      hz.should eq("═")
      vt.should eq("║")
      tl.should eq("╔")
      tr.should eq("╗")
      bl.should eq("╚")
      br.should eq("╝")
    end

    it "returns rounded corners" do
      _, _, tl, tr, bl, br = CRT::Ansi::Border::Rounded.chars
      tl.should eq("╭")
      tr.should eq("╮")
      bl.should eq("╰")
      br.should eq("╯")
    end

    it "returns heavy characters" do
      hz, vt, _, _, _, _ = CRT::Ansi::Border::Heavy.chars
      hz.should eq("━")
      vt.should eq("┃")
    end

    it "returns ASCII fallback" do
      hz, vt, tl, _, _, _ = CRT::Ansi::Border::ASCII.chars
      hz.should eq("-")
      vt.should eq("|")
      tl.should eq("+")
    end

    it "returns spaces for none" do
      hz, vt, tl, _, _, _ = CRT::Ansi::Border::None.chars
      hz.should eq(" ")
      vt.should eq(" ")
      tl.should eq(" ")
    end
  end
end
