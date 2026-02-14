# crt-ansi

Low-level ANSI terminal rendering engine for Crystal.

- Double-buffered, diff-based output (only changed cells are emitted)
- Unicode and emoji-aware cell placement
- Terminal capability detection (color depth, bold/italic/etc., hyperlinks)
- Canvas interface shared by `Render` and `Viewport`
- Panel builder for bordered, filled, text-wrapped regions
- Keyboard and mouse input parsing
- Screen lifecycle (alt screen, raw mode, cursor, resize)

Intended as an engine foundation for higher-level widget systems.

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  crt-ansi:
    github: trans/crt-ansi
```

## Quick Start

```crystal
require "crt-ansi"

CRT::Ansi::Screen.open do |screen|
  screen.write(0, 0, "Hello, terminal!")
  screen.present
  screen.read_key
end
```

## Drawing

`Screen`, `Render`, and `Viewport` all include the `Canvas` module, giving
them the same drawing API.

```crystal
# Place a single grapheme
screen.put(x, y, "X", style)

# Write a string (returns cursor x after last char)
screen.write(x, y, "Hello", style)

# Read a cell back
cell = screen.cell(x, y)
cell.grapheme  # => "H"
cell.style     # => Style

# Clear the buffer
screen.clear

# Flush to terminal (only emits diffs after the first frame)
screen.present
```

### Box Drawing

```crystal
screen.box(x, y, w: 20, h: 5)                          # single-line box
screen.box(x, y, w: 20, h: 5, border: Border::Double)  # double-line box
screen.box(x, y, w: 20)                                 # horizontal line
screen.box(x, y, h: 10)                                 # vertical line
```

### Panels

Panels are a fluent builder for bordered regions with text, fill, and shadow.

```crystal
screen.panel(2, 2, w: 30, h: 8)
  .border(Border::Rounded, style: Style.new(fg: Color.rgb(100, 180, 255)))
  .fill(Style.new(bg: Color.rgb(20, 30, 50)))
  .text("Hello from CRT::Ansi!",
        style: Style.new(fg: Color.rgb(200, 220, 255)),
        wrap: Wrap::Word, pad: 1)
  .shadow
  .draw
```

### Viewport

A virtual buffer for scrollable content. Draw into it like any canvas,
then blit a visible window onto the screen.

```crystal
vp = CRT::Ansi::Viewport.new(width: 80, height: 500)
vp.write(0, 0, "Line 1")
vp.write(0, 200, "Way down here")
vp.box(0, 300, w: 20, h: 5)

# Copy rows 190-200 of the viewport onto the screen at position (5, 3)
screen.blit(vp, x: 5, y: 3, w: 40, h: 10, scroll_y: 190)
screen.present
```

## Styles

Styles are immutable value types composed via `with_*` methods or
constructed directly.

```crystal
include CRT::Ansi

# Direct construction
style = Style.new(bold: true, fg: Color.rgb(255, 100, 0))

# Composition
style = Style.default
  .with_bold
  .with_fg(Color.rgb(255, 100, 0))
  .with_bg(Color.indexed(17))
  .with_hyperlink("https://example.com")

# Merge (right side wins on conflicts)
combined = Style::BOLD.merge(Style.new(italic: true))

# Shortcut constants
Style::BOLD
Style::DIM
Style::ITALIC
Style::UNDERLINE
Style::INVERSE
Style::STRIKE
```

### Colors

```crystal
Color.default                  # terminal default
Color.indexed(196)             # 256-color palette
Color.rgb(255, 100, 0)         # 24-bit truecolor
```

Color output adapts to detected terminal capabilities -- truecolor
values are downsampled to 256 or 16 colors when needed.

## Input

```crystal
CRT::Ansi::Screen.open(raw_mode: true, mouse: true) do |screen|
  loop do
    event = screen.read_event

    case event
    when CRT::Ansi::Key
      break if event.char == "q"
      # event.name, event.ctrl?, event.alt?, event.shift?
    when CRT::Ansi::Mouse
      # event.x, event.y, event.button, event.kind
    end

    screen.present
  end
end
```

## Terminal Capabilities

Capabilities are auto-detected from terminfo and environment variables,
or can be configured manually.

```crystal
# Auto-detect (called by Screen.open)
CRT::Ansi.configure!

# Manual configuration
ctx = CRT::Ansi::Context.new(
  capabilities: CRT::Ansi::Capabilities.new(
    color_support: CRT::Ansi::Capabilities::ColorSupport::Truecolor,
    hyperlinks: true,
  )
)
render = CRT::Ansi::Render.new(STDOUT, 80, 24, context: ctx)
```

## Architecture

```
Screen           Terminal lifecycle, IO, resize, input
  └─ Render      Double-buffered diff renderer (includes Canvas)
       └─ Buffer Cell grid with grapheme/style storage

Viewport         Virtual scrollable buffer (includes Canvas)
  └─ Buffer

Canvas           Shared drawing interface (put, write, box, panel, blit)
Panel            Fluent builder for bordered regions
Style            Immutable text attributes + color + hyperlink
Context          Capabilities + terminal adapter (threaded, not global)
```

## Examples

See the `examples/` directory:

```bash
crystal run examples/demo.cr    # rendering + animation
crystal run examples/panel.cr   # panel builder showcase
crystal run examples/input.cr   # keyboard input
crystal run examples/mouse.cr   # mouse tracking
```

## Development

```bash
crystal spec
```

## Contributors

- [Thomas Sawyer](https://github.com/trans) - creator and maintainer
