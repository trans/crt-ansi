#!/usr/bin/env crystal

# Generates src/crt/ansi/data/widths.txt from Unicode consortium data files.
#
# Usage:
#   crystal run scripts/generate_width_tables.cr
#   crystal run scripts/generate_width_tables.cr -- 16.0.0
#
# Downloads EastAsianWidth.txt and emoji-data.txt, parses them into range
# tables, and writes a compact text format that DisplayWidth reads at
# compile time via {{ read_file }}.

require "http/client"

UNICODE_VERSION = ARGV[0]? || "16.0.0"
UCD_ROOT        = "https://www.unicode.org/Public/#{UNICODE_VERSION}/ucd/"
OUTPUT_PATH     = "#{__DIR__}/../src/crt/ansi/data/widths.txt"

record RRange, low : Int32, high : Int32

def fetch(url : String) : String
  STDERR.puts "Fetching #{url}"
  response = HTTP::Client.get(url)
  unless response.success?
    raise "HTTP #{response.status_code} fetching #{url}"
  end
  response.body
end

def coalesce(ranges : Array(RRange)) : Array(RRange)
  return ranges if ranges.empty?
  sorted = ranges.sort_by(&.low)
  result = [sorted.first]
  sorted.skip(1).each do |r|
    prev = result.last
    if prev.high + 1 >= r.low
      result[-1] = RRange.new(prev.low, {prev.high, r.high}.max)
    else
      result << r
    end
  end
  result
end

def parse_east_asian(body : String)
  combining = [] of RRange
  doublewidth = [] of RRange
  ambiguous = [] of RRange
  narrow = [] of RRange

  body.each_line do |line|
    line = line.strip
    next if line.empty? || line.starts_with?('#')

    # Format: "0000..001F     ; N  # Cc    [32] <control>..."
    parts = line.split(';', 2)
    next if parts.size < 2
    fields = parts[0].strip.split("..")
    prop = parts[1].strip.split.first

    f1 = fields.first.to_i(16)
    f2 = fields.size > 1 ? fields[1].to_i(16) : f1

    combining << RRange.new(f1, f2) if line.includes?("COMBINING")

    case prop
    when "W", "F" then doublewidth << RRange.new(f1, f2)
    when "A"      then ambiguous << RRange.new(f1, f2)
    when "Na"     then narrow << RRange.new(f1, f2)
    end
  end

  {
    combining:   coalesce(combining),
    doublewidth: coalesce(doublewidth),
    ambiguous:   coalesce(ambiguous),
    narrow:      coalesce(narrow),
  }
end

def parse_emoji(body : String) : Array(RRange)
  emoji = [] of RRange

  body.each_line do |line|
    line = line.strip
    next if line.empty? || line.starts_with?('#')

    parts = line.split(';', 2)
    next if parts.size < 2

    prop = parts[1].strip.split(/[\s#]/, 2).first
    next unless prop == "Extended_Pictographic"

    fields = parts[0].strip.split("..")
    f1 = fields.first.to_i(16)
    f2 = fields.size > 1 ? fields[1].to_i(16) : f1
    next if f2 < 0xFF
    emoji << RRange.new(f1, f2)
  end

  coalesce(emoji)
end

def write_section(io : IO, name : String, ranges : Array(RRange))
  io.puts name
  ranges.each do |r|
    io.puts "#{r.low.to_s(16).upcase} #{r.high.to_s(16).upcase}"
  end
  io.puts
end

# Fetch Unicode data
eaw_body = fetch("#{UCD_ROOT}EastAsianWidth.txt")
emoji_body = fetch("#{UCD_ROOT}emoji/emoji-data.txt")

# Parse
tables = parse_east_asian(eaw_body)
emoji = parse_emoji(emoji_body)

# Write output
File.open(OUTPUT_PATH, "w") do |f|
  f.puts "# CRT::Ansi Unicode Width Tables"
  f.puts "# Generated from Unicode #{UNICODE_VERSION}"
  f.puts "# Source: #{UCD_ROOT}"
  f.puts "#"
  f.puts "# Format: SECTION_NAME followed by hex ranges (LOW HIGH), one per line."
  f.puts "# Sections separated by blank lines."
  f.puts "# Regenerate: crystal run scripts/generate_width_tables.cr"
  f.puts

  write_section(f, "COMBINING", tables[:combining])
  write_section(f, "DOUBLEWIDTH", tables[:doublewidth])
  write_section(f, "AMBIGUOUS", tables[:ambiguous])
  write_section(f, "NARROW", tables[:narrow])
  write_section(f, "EMOJI", emoji)
end

count = tables.values.sum(&.size) + emoji.size
STDERR.puts "Wrote #{OUTPUT_PATH} (#{count} ranges across 5 tables, Unicode #{UNICODE_VERSION})"
