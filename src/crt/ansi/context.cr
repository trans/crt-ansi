module CRT::Ansi
  struct Context
    getter capabilities : Capabilities
    getter terminal_adapter : TerminalAdapter
    getter width_resolver : Proc(String, Int32)
    getter grapheme_filter : Proc(String, String)

    def initialize(
      @capabilities : Capabilities = Capabilities.new,
      @terminal_adapter : TerminalAdapter = TerminalAdapter.new,
      @width_resolver : Proc(String, Int32) = ->(g : String) { DisplayWidth.of(g) },
      @grapheme_filter : Proc(String, String) = ->(g : String) { g },
    )
    end

    def self.detect(env = ENV, io : IO = STDOUT) : self
      adapter = TerminalAdapter.detect(env)
      caps = adapter.apply(Capabilities.detect(env, io))

      new(
        capabilities: caps,
        terminal_adapter: adapter,
        width_resolver: adapter.width_resolver,
        grapheme_filter: adapter.grapheme_filter,
      )
    end

    def osc_terminator : Capabilities::OscTerminator
      @capabilities.osc_terminator
    end
  end
end
