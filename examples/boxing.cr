require "../src/crt-ansi"

include CRT::Ansi

CRT::Ansi::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true) do |screen|
  loop do
    screen.clear

    # Title
    title_style = Style.new(fg: Color.rgb(0, 0, 0), bg: Color.rgb(255, 200, 80), bold: true)
    screen.write(0, 0, " " * screen.width, title_style)
    screen.write(2, 0, "Boxing Demo — Border Intersection Resolution", title_style)

    label_style = Style.new(fg: Color.rgb(180, 180, 180), dim: true)

    # --- Single: 2x2 grid showing corners, T-junctions, and cross ---
    screen.write(2, 2, "Single", label_style)
    b1 = Boxing.new(border: Border::Single)
    b1.style = Style.new(fg: Color.rgb(100, 180, 255))
    b1.add(x: 2, y: 3, w: 12, h: 4)
    b1.add(x: 13, y: 3, w: 12, h: 4)
    b1.add(x: 2, y: 6, w: 12, h: 4)
    b1.add(x: 13, y: 6, w: 12, h: 4)
    b1.draw(screen.render)

    # Labels in cells
    cell_style = Style.new(fg: Color.rgb(60, 120, 180))
    screen.write(5, 4, "┌  ┬  ┐", cell_style)
    screen.write(16, 4, "corners", cell_style)
    screen.write(5, 7, "├  ┼  ┤", cell_style)
    screen.write(15, 7, "T & cross", cell_style)

    # --- Double ---
    screen.write(28, 2, "Double", label_style)
    b2 = Boxing.new(border: Border::Double)
    b2.style = Style.new(fg: Color.rgb(255, 200, 80))
    b2.add(x: 28, y: 3, w: 12, h: 4)
    b2.add(x: 39, y: 3, w: 12, h: 4)
    b2.add(x: 28, y: 6, w: 12, h: 4)
    b2.add(x: 39, y: 6, w: 12, h: 4)
    b2.draw(screen.render)

    # --- Heavy ---
    screen.write(54, 2, "Heavy", label_style)
    b3 = Boxing.new(border: Border::Heavy)
    b3.style = Style.new(fg: Color.rgb(255, 100, 100))
    b3.add(x: 54, y: 3, w: 12, h: 4)
    b3.add(x: 65, y: 3, w: 12, h: 4)
    b3.add(x: 54, y: 6, w: 12, h: 4)
    b3.add(x: 65, y: 6, w: 12, h: 4)
    b3.draw(screen.render)

    # --- Rounded: corners are round, intersections fall back to single ---
    screen.write(2, 11, "Rounded (round corners, single at intersections)", label_style)
    b4 = Boxing.new(border: Border::Rounded)
    b4.style = Style.new(fg: Color.rgb(100, 255, 100))
    b4.add(x: 2, y: 12, w: 12, h: 4)
    b4.add(x: 13, y: 12, w: 12, h: 4)
    b4.add(x: 2, y: 15, w: 12, h: 4)
    b4.add(x: 13, y: 15, w: 12, h: 4)
    b4.draw(screen.render)

    # --- ASCII ---
    screen.write(28, 11, "ASCII", label_style)
    b5 = Boxing.new(border: Border::ASCII)
    b5.style = Style.new(fg: Color.rgb(200, 200, 200))
    b5.add(x: 28, y: 12, w: 12, h: 4)
    b5.add(x: 39, y: 12, w: 12, h: 4)
    b5.add(x: 28, y: 15, w: 12, h: 4)
    b5.add(x: 39, y: 15, w: 12, h: 4)
    b5.draw(screen.render)

    # --- Incremental: boxes added one at a time ---
    screen.write(54, 11, "3-wide strip", label_style)
    b6 = Boxing.new(border: Border::Single)
    b6.style = Style.new(fg: Color.rgb(200, 150, 255))
    b6.add(x: 54, y: 12, w: 8, h: 3)
    b6.add(x: 61, y: 12, w: 8, h: 3)
    b6.add(x: 68, y: 12, w: 8, h: 3)
    b6.add(x: 54, y: 14, w: 8, h: 3)
    b6.add(x: 61, y: 14, w: 8, h: 3)
    b6.add(x: 68, y: 14, w: 8, h: 3)
    b6.draw(screen.render)

    # Footer
    screen.write(2, 20, "Press 'q' to quit", Style.new(fg: Color.rgb(120, 120, 120), italic: true))

    screen.present

    key = screen.read_key
    break unless key
    break if key.char? && key.char == "q"
  end
end
