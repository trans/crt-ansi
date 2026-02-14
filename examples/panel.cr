require "../src/crt-ansi"

include CRT::Ansi

CRT::Ansi::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  loop do
    screen.clear

    # Title bar
    title_style = Style.new(fg: Color.rgb(0, 0, 0), bg: Color.rgb(255, 200, 80), bold: true)
    screen.write(0, 0, " " * screen.width, title_style)
    screen.write(2, 0, "Panel Demo", title_style)

    # Panel 1: Simple bordered box with fill
    screen.panel(2, 2, w: 24, h: 8)
      .border(Border::Rounded, style: Style.new(fg: Color.rgb(100, 180, 255)))
      .fill(Style.new(bg: Color.rgb(20, 30, 50)))
      .text("Hello from CRT::Ansi!\n\nThis panel has a rounded border, a dark blue fill, and left-aligned text.",
            style: Style.new(fg: Color.rgb(200, 220, 255)),
            wrap: Wrap::Word, pad: 1)
      .shadow
      .draw

    # Panel 2: Centered text, double border
    screen.panel(28, 2, w: 26, h: 8)
      .border(Border::Double, style: Style.new(fg: Color.rgb(255, 200, 80)))
      .fill(Style.new(bg: Color.rgb(40, 30, 10)))
      .text("Centered Text\n\nDouble border with warm colors and centered alignment.",
            style: Style.new(fg: Color.rgb(255, 220, 150)),
            align: Align::Center, wrap: Wrap::Word, pad: 1)
      .shadow
      .draw

    # Panel 3: Heavy border, right-aligned
    screen.panel(56, 2, w: 22, h: 8)
      .border(Border::Heavy, style: Style.new(fg: Color.rgb(255, 100, 100)))
      .fill(Style.new(bg: Color.rgb(40, 10, 10)))
      .text("Right Aligned\n\nHeavy border with right-aligned text.",
            style: Style.new(fg: Color.rgb(255, 180, 180)),
            align: Align::Right, wrap: Wrap::Word, pad: 1)
      .draw

    # Panel 4: Word wrapping demo
    long_text = "The quick brown fox jumps over the lazy dog. " \
                "This is a demonstration of automatic word wrapping " \
                "within a bordered panel region. Words that would " \
                "overflow the line break to the next row."
    screen.panel(2, 12, w: 50, h: 8)
      .border(Border::Single, style: Style.new(fg: Color.rgb(100, 255, 100)))
      .fill(Style.new(bg: Color.rgb(10, 30, 10)))
      .text(long_text,
            style: Style.new(fg: Color.rgb(180, 255, 180)),
            wrap: Wrap::Word, pad: 1)
      .shadow
      .draw

    # Panel 5: ASCII border, fill character
    screen.panel(54, 12, w: 24, h: 8)
      .border(Border::ASCII)
      .fill(Style::Char.new(".", Style.new(fg: Color.rgb(60, 60, 60))))
      .text("ASCII border\nwith dot fill",
            style: Style.new(fg: Color.rgb(200, 200, 200), bold: true),
            align: Align::Center, wrap: Wrap::Word)
      .draw

    # Footer
    screen.write(2, 21, "Press 'q' to quit", Style.new(fg: Color.rgb(120, 120, 120), italic: true))

    screen.present

    key = screen.read_key
    break unless key
    break if key.char? && key.char == "q"
  end
end
