# TODO

## P0: Correctness and Terminal Compatibility

- [ ] Replace heuristic width logic with `uni_char_width` (or equivalent) as default resolver and keep adapter-specific overrides.
- [ ] Add grapheme segmentation fallback strategy for terminals with known ZWJ/emoji quirks (Ghostty, Kitty, VTE variants).
- [ ] Add adapter-level hyperlink policies:
  - [ ] OSC 8 terminator mode (`ST`/`BEL`) per terminal.
  - [ ] optional hyperlink disable for terminals/multiplexers with broken handling.
- [ ] Add integration tests for real terminal output snapshots (Ghostty, Kitty, GNOME Console, WezTerm, iTerm2).

## P0: Rendering Engine Core

- [ ] Add explicit frame API (`begin_frame`/`end_frame`) and dirty-region tracking to avoid scanning full buffers each present.
- [ ] Add configurable diff strategy:
  - [ ] row-span diff (current baseline),
  - [ ] run-length diff,
  - [ ] full redraw threshold when diff cost is high.
- [ ] Improve wide-cell overwrite semantics for all edge cases (adjacent wide chars, truncation at boundaries, clear/fill interactions).
- [ ] Add cursor visibility/shape state management in renderer (not just show/hide in demo cleanup).

## P1: Capabilities and Terminfo Integration

- [ ] Expand terminfo mapping beyond current basics:
  - [ ] style capability confidence scoring,
  - [ ] color capability reconciliation (terminfo + env + adapter),
  - [ ] cursor addressing fallbacks when `cup` unavailable.
- [ ] Add explicit multiplexer awareness (`tmux`, `screen`, `zellij`) and safe defaults for hyperlinks/colors.
- [ ] Add public diagnostics API to inspect final resolved capabilities and adapter decisions.

## P1: API Surface for Upstream Widget Layer

- [ ] Add drawing primitives to `Buffer`:
  - [ ] `fill_rect`, `stroke_rect`, `blit`, clipping regions.
- [ ] Add style stack / painter abstraction to reduce repetitive style passing.
- [ ] Add text layout helpers:
  - [ ] truncation with ellipsis,
  - [ ] alignment,
  - [ ] wrapping by display width.
- [ ] Define a stable minimal API contract for external widget libraries.

## P1: Performance

- [ ] Add microbenchmarks for:
  - [ ] large frame updates,
  - [ ] sparse diffs,
  - [ ] emoji-heavy content.
- [ ] Reduce allocations in hot paths (`Graphemes.each`, style transitions, span rendering).
- [ ] Add optional write batching policy / flush control for high-FPS redraw loops.

## P2: Reliability and Tooling

- [ ] Add fuzz/property tests for Unicode/grapheme/width edge cases.
- [ ] Add CI matrix:
  - [ ] Crystal stable/nightly,
  - [ ] Linux/macOS,
  - [ ] lint + spec + benchmark smoke.
- [ ] Add changelog + versioning/release checklist.
- [ ] Add richer examples (dashboard, list/table, log viewer) to validate widget-layer readiness.
