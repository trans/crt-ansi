require "../src/crt-ansi"

include CRT::Ansi

CRT::Ansi::Screen.open(alt_screen: true, raw_mode: true, hide_cursor: true, mouse: true) do |screen|
  header_style = Style.new(fg: Color.rgb(255, 200, 80), bold: true)
  info_style = Style.new(fg: Color.rgb(180, 200, 220))
  dot_style = Style.new(fg: Color.rgb(100, 255, 100), bold: true)
  trail_style = Style.new(fg: Color.rgb(40, 80, 40))
  event_style = Style.new(fg: Color.rgb(200, 200, 200))
  dim_style = Style.new(fg: Color.rgb(80, 80, 80))

  events = [] of String
  dots = [] of {Int32, Int32}

  loop do
    screen.clear

    # Header
    screen.panel(0, 0, h: screen.width, v: 1)
      .fill(Style.new(bg: Color.rgb(30, 40, 60)))
      .text(" Mouse Demo  |  Click to place dots  |  Press 'q' to quit",
            style: Style.new(fg: Color.rgb(255, 200, 80), bg: Color.rgb(30, 40, 60), bold: true))
      .draw

    # Draw trail dots
    dots.each_with_index do |(x, y), i|
      if i == dots.size - 1
        screen.put(x, y, "\u{2588}", dot_style)  # full block for latest
      else
        screen.put(x, y, "\u{00B7}", trail_style)  # middle dot for trail
      end
    end

    # Event log panel (right side)
    log_x = screen.width - 32
    log_h = 30
    log_v = screen.height - 2
    if log_x > 40 && log_v > 4
      screen.panel(log_x, 1, h: log_h, v: log_v)
        .border(Border::Rounded, style: Style.new(fg: Color.rgb(60, 80, 120)))
        .fill(Style.new(bg: Color.rgb(15, 20, 30)))
        .text("Event Log", style: Style.new(fg: Color.rgb(120, 160, 200), bold: true),
              align: Align::Center)
        .draw

      # Show recent events
      visible = log_v - 4
      start = {0, events.size - visible}.max
      events[start..].each_with_index do |ev, i|
        screen.write(log_x + 2, 3 + i, ev[0, log_h - 4], event_style)
      end
    end

    # Coordinates display
    screen.write(2, screen.height - 1, "Events: #{events.size}  Dots: #{dots.size}", dim_style)

    screen.present

    event = screen.read_event
    break unless event

    case event
    when Key
      break if event.char? && event.char == "q"
      events << "Key: #{event}"
    when Mouse
      events << "#{event}"
      if event.action.press? && (event.button.left? || event.button.right?)
        dots << {event.x, event.y}
        dots.shift if dots.size > 100
      end
    end
  end
end
