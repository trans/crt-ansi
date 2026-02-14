require "../src/crt-ansi"

title_style = CRT::Ansi::Style.default.with_fg(CRT::Ansi::Color.rgb(255, 200, 80))
link_style = CRT::Ansi::Style.default
  .with_fg(CRT::Ansi::Color.rgb(120, 200, 255))
  .with_hyperlink("https://crystal-lang.org")

CRT::Ansi::Screen.open(alt_screen: true, hide_cursor: true, raw_mode: false) do |screen|
  120.times do |frame|
    screen.clear

    screen.write(0, 0, "crt-ansi rendering demo", title_style)
    screen.write(0, 2, "Hyperlink: ", CRT::Ansi::Style.default)
    screen.write(11, 2, "crystal-lang.org", link_style)
    screen.write(0, 4, "Unicode/emoji: \u{1F44D} \u{1F680} \u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}")
    screen.write(0, 6, "Frame: #{frame}")

    x = frame % 40
    screen.put(x, 7, "\u{2588}", CRT::Ansi::Style.default.with_fg(CRT::Ansi::Color.indexed(46)))

    screen.present
    sleep 50.milliseconds
  end
end
