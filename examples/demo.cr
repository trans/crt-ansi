require "../src/crt-ansi"

stdout = STDOUT
CRT::Ansi.configure!
renderer = CRT::Ansi::Renderer.new(stdout, 50, 8)

title_style = CRT::Ansi::Style.default.with_fg(CRT::Ansi::Color.rgb(255, 200, 80))
link_style = CRT::Ansi::Style.default
  .with_fg(CRT::Ansi::Color.rgb(120, 200, 255))
  .with_hyperlink("https://crystal-lang.org")

begin
  stdout << "\e[2J\e[H\e[?25l"

  120.times do |frame|
    b = renderer.back_buffer
    b.clear

    b.write(0, 0, "crt-ansi rendering demo", title_style)
    b.write(0, 2, "Hyperlink: ", CRT::Ansi::Style.default)
    b.write(11, 2, "crystal-lang.org", link_style)
    b.write(0, 4, "Unicode/emoji: \u{1F44D} \u{1F680} \u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}")
    b.write(0, 6, "Frame: #{frame}")

    x = frame % 40
    b.put(x, 7, "\u{2588}", CRT::Ansi::Style.default.with_fg(CRT::Ansi::Color.indexed(46)))

    renderer.present
    sleep 50.milliseconds
  end
ensure
  renderer.reset_terminal_state!
  stdout << "\e[?25h\n"
end
