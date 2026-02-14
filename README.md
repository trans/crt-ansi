# crt-ansi

`crt-ansi` is a low-level ANSI rendering core for Crystal TUI stacks.
It focuses on:

- Double-buffered rendering (`front`/`back` frame buffers)
- Diff-based output (only changed cells are emitted)
- Unicode/emoji-aware cell placement
- OSC 8 hyperlinks

This shard is intended as a rendering engine foundation for higher-level widget systems.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     crt-ansi:
       github: trans/crt-ansi
   ```

2. Run `shards install`

## Usage

```crystal
require "crt-ansi"

io = STDOUT
renderer = CRT::Ansi::Renderer.new(io, 80, 24)

# Draw into the back buffer.
renderer.back_buffer.write(0, 0, "Hello ")
link_style = CRT::Ansi::Style.default.with_hyperlink("https://crystal-lang.org")
renderer.back_buffer.write(6, 0, "Crystal", link_style)
renderer.back_buffer.put(14, 0, "👍")

# Present frame: first call emits full buffer, next calls emit diffs.
renderer.present

# Optional: detect terminal capabilities and configure adapters.
# CRT::Ansi.configure!
#
# Or construct a custom context:
# ctx = CRT::Ansi::Context.new(
#   capabilities: CRT::Ansi::Capabilities.new(
#     color_support: CRT::Ansi::Capabilities::ColorSupport::Truecolor,
#     hyperlinks: true
#   )
# )
# renderer = CRT::Ansi::Renderer.new(io, 80, 24, context: ctx)
```

## Development

Run specs:

```bash
crystal spec
```

## Contributors

- [Thomas Sawyer](https://github.com/trans) - creator and maintainer
