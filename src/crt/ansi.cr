module CRT::Ansi
end

require "./ansi/version"
require "./ansi/capabilities"
require "./ansi/color"
require "./ansi/hyperlink"
require "./ansi/style"
require "./ansi/graphemes"
require "./ansi/display_width"
require "./ansi/terminal_adapter"
require "./ansi/context"
require "./ansi/cell"
require "./ansi/buffer"
require "./ansi/style_char"
require "./ansi/align"
require "./ansi/styled_text"
require "./ansi/canvas"
require "./ansi/border"
require "./ansi/panel"
require "./ansi/render"
require "./ansi/viewport"
require "./ansi/key"
require "./ansi/mouse"
require "./ansi/event"
require "./ansi/input"
require "./ansi/screen"

module CRT::Ansi
  @@context : Context = Context.new

  def self.context : Context
    @@context
  end

  def self.context=(ctx : Context) : Context
    @@context = ctx
  end

  def self.configure!(env = ENV, io : IO = STDOUT) : Context
    @@context = Context.detect(env, io)
  end
end
