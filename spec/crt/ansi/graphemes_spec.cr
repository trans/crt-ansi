require "../../spec_helper"

describe CRT::Ansi::Graphemes do
  it "returns no clusters for empty strings" do
    clusters = [] of String
    CRT::Ansi::Graphemes.each("") { |cluster| clusters << cluster }
    clusters.should eq([] of String)
  end
end
