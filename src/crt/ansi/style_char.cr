module CRT::Ansi
  struct Style
    struct Char
      getter char : String
      getter style : Style

      def initialize(@char : String = " ", @style : Style = Style.default)
      end

      def initialize(char : ::Char, @style : Style = Style.default)
        @char = char.to_s
      end
    end
  end
end
