module CRT::Ansi
  enum Border
    Single
    Double
    Rounded
    Heavy
    ASCII
    None

    # Returns {horizontal, vertical, top_left, top_right, bottom_left, bottom_right}
    def chars : {String, String, String, String, String, String}
      case self
      in .single?  then {"─", "│", "┌", "┐", "└", "┘"}
      in .double?  then {"═", "║", "╔", "╗", "╚", "╝"}
      in .rounded? then {"─", "│", "╭", "╮", "╰", "╯"}
      in .heavy?   then {"━", "┃", "┏", "┓", "┗", "┛"}
      in .ascii?   then {"-", "|", "+", "+", "+", "+"}
      in .none?    then {" ", " ", " ", " ", " ", " "}
      end
    end
  end
end
