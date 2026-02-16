module CRT::Ansi
  struct Color
    enum Mode
      Default
      Indexed
      RGB
    end

    getter mode : Mode
    getter index : Int32
    getter red : Int32
    getter green : Int32
    getter blue : Int32

    DEFAULT = Color.new

    def initialize
      @mode = Mode::Default
      @index = 0
      @red = 0
      @green = 0
      @blue = 0
    end

    def self.default : self
      DEFAULT
    end

    def self.indexed(index : Int) : self
      value = index.to_i
      unless (0..255).includes?(value)
        raise ArgumentError.new("indexed color must be in 0..255")
      end

      new(Mode::Indexed, value, 0, 0, 0)
    end

    def self.rgb(red : Int, green : Int, blue : Int) : self
      r = normalize_channel(red, "red")
      g = normalize_channel(green, "green")
      b = normalize_channel(blue, "blue")

      new(Mode::RGB, 0, r, g, b)
    end

    def default? : Bool
      @mode.default?
    end

    # Linear interpolation between two colors. Returns an RGB color at
    # position `t` along the line from `a` to `b` (0.0 = a, 1.0 = b).
    # Default-mode colors are treated as black (0, 0, 0).
    def self.lerp(a : Color, b : Color, t : Float64) : Color
      ar, ag, ab = a.default? ? {0, 0, 0} : {a.red, a.green, a.blue}
      br, bg, bb = b.default? ? {0, 0, 0} : {b.red, b.green, b.blue}
      rgb(
        (ar + (br - ar) * t).round.to_i.clamp(0, 255),
        (ag + (bg - ag) * t).round.to_i.clamp(0, 255),
        (ab + (bb - ab) * t).round.to_i.clamp(0, 255))
    end

    def append_fg_sgr(io : IO, capabilities : Capabilities = CRT::Ansi.context.capabilities) : Nil
      case capabilities.color_support
      in .none?
        io << "39"
      in .ansi16?
        io << ansi16_fg_code
      in .ansi256?
        io << "38;5;" << color_index_256
      in .truecolor?
        case @mode
        in .default?
          io << "39"
        in .indexed?
          io << "38;5;" << @index
        in .rgb?
          io << "38;2;" << @red << ';' << @green << ';' << @blue
        end
      end
    end

    def append_bg_sgr(io : IO, capabilities : Capabilities = CRT::Ansi.context.capabilities) : Nil
      case capabilities.color_support
      in .none?
        io << "49"
      in .ansi16?
        io << ansi16_bg_code
      in .ansi256?
        io << "48;5;" << color_index_256
      in .truecolor?
        case @mode
        in .default?
          io << "49"
        in .indexed?
          io << "48;5;" << @index
        in .rgb?
          io << "48;2;" << @red << ';' << @green << ';' << @blue
        end
      end
    end

    protected def initialize(@mode : Mode, @index : Int32, @red : Int32, @green : Int32, @blue : Int32)
    end

    private def self.normalize_channel(value : Int, name : String) : Int32
      channel = value.to_i
      unless (0..255).includes?(channel)
        raise ArgumentError.new("#{name} channel must be in 0..255")
      end
      channel
    end

    private def ansi16_fg_code : Int32
      index = ansi16_index
      if index < 8
        30 + index
      else
        90 + (index - 8)
      end
    end

    private def ansi16_bg_code : Int32
      index = ansi16_index
      if index < 8
        40 + index
      else
        100 + (index - 8)
      end
    end

    private def ansi16_index : Int32
      case @mode
      in .default?
        0
      in .indexed?
        self.class.index256_to_ansi16(@index)
      in .rgb?
        self.class.rgb_to_ansi16(@red, @green, @blue)
      end
    end

    private def color_index_256 : Int32
      case @mode
      in .default?
        0
      in .indexed?
        @index
      in .rgb?
        self.class.rgb_to_ansi256(@red, @green, @blue)
      end
    end

    protected def self.index256_to_ansi16(index : Int32) : Int32
      return index if index < 16

      if index >= 232
        gray = index - 232
        return 0 if gray < 8
        return 8 if gray < 18
        return 7 if gray < 22
        return 15
      end

      cube = index - 16
      r = cube // 36
      g = (cube % 36) // 6
      b = cube % 6
      rgb_to_ansi16(level_to_255(r), level_to_255(g), level_to_255(b))
    end

    protected def self.level_to_255(level : Int32) : Int32
      return 0 if level == 0
      55 + level * 40
    end

    protected def self.rgb_to_ansi256(r : Int32, g : Int32, b : Int32) : Int32
      if r == g && g == b
        return 16 if r < 8
        return 231 if r > 248
        return 232 + ((r - 8) * 24 // 247)
      end

      r_idx = (r * 5 + 127) // 255
      g_idx = (g * 5 + 127) // 255
      b_idx = (b * 5 + 127) // 255
      16 + (36 * r_idx) + (6 * g_idx) + b_idx
    end

    private ANSI16_RGB = {
      {0, 0, 0},
      {205, 0, 0},
      {0, 205, 0},
      {205, 205, 0},
      {0, 0, 238},
      {205, 0, 205},
      {0, 205, 205},
      {229, 229, 229},
      {127, 127, 127},
      {255, 0, 0},
      {0, 255, 0},
      {255, 255, 0},
      {92, 92, 255},
      {255, 0, 255},
      {0, 255, 255},
      {255, 255, 255},
    }

    protected def self.rgb_to_ansi16(r : Int32, g : Int32, b : Int32) : Int32
      best_index = 0
      best_distance = Int64::MAX

      ANSI16_RGB.each_with_index do |(pr, pg, pb), idx|
        dr = r - pr
        dg = g - pg
        db = b - pb
        distance = (dr * dr + dg * dg + db * db).to_i64

        if distance < best_distance
          best_index = idx.to_i32
          best_distance = distance
        end
      end

      best_index
    end
  end
end
