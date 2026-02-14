module CRT::Ansi
  struct TerminalAdapter
    enum Kind
      Unknown
      Ghostty
      Kitty
      VTE
      WezTerm
      ITerm
    end

    getter kind : Kind
    getter term_program : String
    getter term : String

    def initialize(@kind : Kind = Kind::Unknown, @term_program : String = "", @term : String = "")
    end

    def self.detect(env = ENV) : self
      term_program = read_env(env, "TERM_PROGRAM").downcase
      term = read_env(env, "TERM").downcase

      if term_program == "ghostty" || env["GHOSTTY_RESOURCES_DIR"]? != nil
        return new(Kind::Ghostty, term_program, term)
      end

      if env["KITTY_WINDOW_ID"]? != nil
        return new(Kind::Kitty, term_program, term)
      end

      if term_program == "wezterm"
        return new(Kind::WezTerm, term_program, term)
      end

      if term_program == "iterm.app"
        return new(Kind::ITerm, term_program, term)
      end

      if env["VTE_VERSION"]? != nil || term.includes?("vte")
        return new(Kind::VTE, term_program, term)
      end

      new(Kind::Unknown, term_program, term)
    end

    def apply(base : Capabilities) : Capabilities
      case @kind
      in .ghostty?
        base.copy_with(
          hyperlinks: true,
          osc_terminator: Capabilities::OscTerminator::BEL
        )
      in .kitty?
        base.copy_with(hyperlinks: true)
      in .vte?
        base.copy_with(hyperlinks: true)
      in .wez_term?
        base.copy_with(hyperlinks: true)
      in .i_term?
        base.copy_with(hyperlinks: true)
      in .unknown?
        base
      end
    end

    def width_resolver : Proc(String, Int32)
      ->(grapheme : String) { DisplayWidth.of(grapheme) }
    end

    def grapheme_filter : Proc(String, String)
      ->(grapheme : String) { grapheme }
    end

    private def self.read_env(env, key : String) : String
      env[key]? || ""
    end
  end

  # Convenience alias
  alias TerminalKind = TerminalAdapter::Kind
end
