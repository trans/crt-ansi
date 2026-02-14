require "../src/crt-ansi"

CRT::Ansi::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: false) do |screen|
  screen.write(0, 0, "Press keys to see them parsed. Press 'q' to quit.")
  screen.present

  row = 2
  loop do
    key = screen.read_key
    break unless key
    break if key.char? && key.char == "q" && !key.ctrl? && !key.alt?

    screen.write(0, row, "#{key}                        ")
    screen.present
    row += 1
    if row >= screen.height - 1
      row = 2
      screen.clear
      screen.write(0, 0, "Press keys to see them parsed. Press 'q' to quit.")
    end
  end
end
