module CRT::Ansi
  struct Hyperlink
    getter uri : String
    getter id : String?

    def initialize(@uri : String, @id : String? = nil)
      raise ArgumentError.new("hyperlink uri must not be empty") if @uri.empty?
    end

    def open_sequence(osc_terminator : Capabilities::OscTerminator = CRT::Ansi.context.osc_terminator) : String
      params = if value = @id
                 "id=#{sanitize_param(value)}"
               else
                 ""
               end

      "\e]8;#{params};#{@uri}#{osc_end(osc_terminator)}"
    end

    def self.close_sequence(osc_terminator : Capabilities::OscTerminator = CRT::Ansi.context.osc_terminator) : String
      "\e]8;;#{osc_end(osc_terminator)}"
    end

    private def sanitize_param(value : String) : String
      value.gsub(/[;:]/, "")
    end

    private def osc_end(osc_terminator : Capabilities::OscTerminator) : String
      osc_terminator.st? ? "\e\\" : "\a"
    end

    private def self.osc_end(osc_terminator : Capabilities::OscTerminator) : String
      osc_terminator.st? ? "\e\\" : "\a"
    end
  end
end
