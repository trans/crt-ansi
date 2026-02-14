module CRT::Ansi
  struct Mouse
    enum Button
      Left
      Middle
      Right
      ScrollUp
      ScrollDown
      ScrollLeft
      ScrollRight
      None
    end

    enum Action
      Press
      Release
      Motion
    end

    getter button : Button
    getter action : Action
    getter x : Int32
    getter y : Int32
    getter? shift : Bool
    getter? alt : Bool
    getter? ctrl : Bool

    def initialize(@button : Button, @action : Action, @x : Int32, @y : Int32,
                   *, @shift : Bool = false, @alt : Bool = false, @ctrl : Bool = false)
    end

    def ==(other : Mouse) : Bool
      @button == other.button && @action == other.action &&
        @x == other.x && @y == other.y &&
        @shift == other.shift? && @alt == other.alt? && @ctrl == other.ctrl?
    end

    def to_s(io : IO) : Nil
      if @ctrl
        io << "Ctrl+"
      end
      if @alt
        io << "Alt+"
      end
      if @shift
        io << "Shift+"
      end
      io << @button << " " << @action << " (" << @x << "," << @y << ")"
    end
  end
end
