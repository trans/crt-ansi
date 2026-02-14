require "term-terminfo"

module CRT::Ansi
  struct Capabilities
    enum ColorSupport
      None
      ANSI16
      ANSI256
      Truecolor
    end

    enum OscTerminator
      ST
      BEL
    end

    getter color_support : ColorSupport
    getter hyperlinks : Bool
    getter cursor_addressing : Bool

    getter bold : Bool
    getter dim : Bool
    getter italic : Bool
    getter underline : Bool
    getter blink : Bool
    getter inverse : Bool
    getter strikethrough : Bool

    getter osc_terminator : OscTerminator

    def initialize(
      @color_support : ColorSupport = ColorSupport::ANSI256,
      @hyperlinks : Bool = true,
      @cursor_addressing : Bool = true,
      @bold : Bool = true,
      @dim : Bool = true,
      @italic : Bool = true,
      @underline : Bool = true,
      @blink : Bool = true,
      @inverse : Bool = true,
      @strikethrough : Bool = true,
      @osc_terminator : OscTerminator = OscTerminator::ST,
    )
    end

    def self.detect(env = ENV, io : IO = STDOUT) : self
      if env == ENV
        if capabilities = detect_from_terminfo(env, io)
          return capabilities
        end
      end

      detect_from_env(env, env == ENV ? io.tty? : true)
    end

    def color? : Bool
      !@color_support.none?
    end

    def ansi16? : Bool
      @color_support.ansi16?
    end

    def ansi256? : Bool
      @color_support.ansi256?
    end

    def truecolor? : Bool
      @color_support.truecolor?
    end

    def copy_with(
      color_support : ColorSupport = @color_support,
      hyperlinks : Bool = @hyperlinks,
      cursor_addressing : Bool = @cursor_addressing,
      bold : Bool = @bold,
      dim : Bool = @dim,
      italic : Bool = @italic,
      underline : Bool = @underline,
      blink : Bool = @blink,
      inverse : Bool = @inverse,
      strikethrough : Bool = @strikethrough,
      osc_terminator : OscTerminator = @osc_terminator,
    ) : self
      Capabilities.new(
        color_support: color_support,
        hyperlinks: hyperlinks,
        cursor_addressing: cursor_addressing,
        bold: bold,
        dim: dim,
        italic: italic,
        underline: underline,
        blink: blink,
        inverse: inverse,
        strikethrough: strikethrough,
        osc_terminator: osc_terminator
      )
    end

    private def self.detect_from_terminfo(env, io : IO) : self?
      tty = Term::Terminfo.tty?(io)
      term = read_env(env, "TERM").downcase
      dumb = term.empty? || term == "dumb"
      no_color = env["NO_COLOR"]? != nil

      colors = if tty && !dumb
                 Term::Terminfo.capabilities[:numeric].colors
               else
                 0
               end

      color_support = if !tty || dumb || no_color
                        ColorSupport::None
                      elsif Term::Terminfo.supports?(:truecolor) || colors >= 16_777_216
                        ColorSupport::Truecolor
                      elsif colors >= 256 || Term::Terminfo.supports?(:"256color")
                        ColorSupport::ANSI256
                      elsif colors > 0 || Term::Terminfo.supports?(:color)
                        ColorSupport::ANSI16
                      else
                        ColorSupport::None
                      end

      supports = ->(name : Symbol) { tty && !dumb && Term::Terminfo.supports?(name) }
      cup = (tty && !dumb) ? Term::Terminfo.database.get_string("cup") : nil
      hyperlinks = detect_hyperlinks(env, dumb, tty)
      osc_terminator = detect_osc_terminator(env)

      new(
        color_support: color_support,
        hyperlinks: hyperlinks,
        cursor_addressing: tty && !dumb && !cup.nil?,
        bold: supports.call(:bold),
        dim: supports.call(:dim),
        italic: supports.call(:italic),
        underline: supports.call(:underline),
        blink: supports.call(:blink),
        inverse: supports.call(:reverse),
        strikethrough: supports.call(:strikethrough),
        osc_terminator: osc_terminator
      )
    rescue
      nil
    end

    private def self.detect_from_env(env, tty : Bool) : self
      term = read_env(env, "TERM").downcase
      colorterm = read_env(env, "COLORTERM").downcase

      dumb = term.empty? || term == "dumb"
      no_color = env["NO_COLOR"]? != nil

      color_support = if !tty || dumb || no_color
                        ColorSupport::None
                      elsif colorterm.includes?("truecolor") || colorterm.includes?("24bit")
                        ColorSupport::Truecolor
                      elsif term.includes?("256color")
                        ColorSupport::ANSI256
                      else
                        ColorSupport::ANSI16
                      end

      hyperlinks = detect_hyperlinks(env, dumb, tty)
      osc_terminator = detect_osc_terminator(env)
      linux_console = term == "linux"

      new(
        color_support: color_support,
        hyperlinks: hyperlinks,
        cursor_addressing: tty && !dumb,
        italic: !linux_console,
        blink: !linux_console,
        osc_terminator: osc_terminator
      )
    end

    private def self.detect_hyperlinks(env, dumb : Bool, tty : Bool) : Bool
      if raw = env["CRT_ANSI_HYPERLINKS"]?
        return parse_bool(raw, default: true)
      end

      return false if dumb || !tty

      term_program = read_env(env, "TERM_PROGRAM").downcase
      return true if term_program == "wezterm"
      return true if term_program == "ghostty"
      return true if term_program == "iterm.app"
      return true if term_program == "vscode"

      return true if env["KITTY_WINDOW_ID"]? != nil
      return true if env["VTE_VERSION"]? != nil
      return true if env["WT_SESSION"]? != nil
      return true if env["GHOSTTY_RESOURCES_DIR"]? != nil

      true
    end

    private def self.detect_osc_terminator(env) : OscTerminator
      if raw = env["CRT_ANSI_OSC_TERMINATOR"]?
        return parse_osc_terminator(raw)
      end

      term_program = read_env(env, "TERM_PROGRAM").downcase
      return OscTerminator::BEL if term_program == "ghostty"
      return OscTerminator::BEL if env["GHOSTTY_RESOURCES_DIR"]? != nil

      OscTerminator::ST
    end

    private def self.parse_osc_terminator(raw : String) : OscTerminator
      value = raw.downcase
      return OscTerminator::BEL if value == "bel"
      return OscTerminator::ST if value == "st"
      OscTerminator::ST
    end

    private def self.parse_bool(raw : String, default : Bool) : Bool
      value = raw.downcase
      return true if {"1", "true", "yes", "on"}.includes?(value)
      return false if {"0", "false", "no", "off"}.includes?(value)
      default
    end

    private def self.read_env(env, key : String) : String
      env[key]? || ""
    end
  end

  # Convenience alias so callers can use CRT::Ansi::OscTerminator
  alias OscTerminator = Capabilities::OscTerminator
end
