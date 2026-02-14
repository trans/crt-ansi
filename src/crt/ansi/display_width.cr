module CRT::Ansi
  module DisplayWidth
    extend self

    ZERO_WIDTH_JOINER     = 0x200D
    ZERO_WIDTH_NON_JOINER = 0x200C

    def of(grapheme : String) : Int32
      return 1 if grapheme.empty?

      width = 0
      has_visible_codepoint = false

      grapheme.each_char do |char|
        ord = char.ord
        next if zero_width?(char, ord)

        has_visible_codepoint = true
        candidate = wide?(ord) ? 2 : 1
        width = candidate if candidate > width
      end

      if !has_visible_codepoint
        return 2 if grapheme.includes?('\u{200D}') || grapheme.includes?('\u{FE0F}')
        return 1
      end

      width
    end

    private def zero_width?(char : Char, ord : Int32) : Bool
      char.mark? ||
        ord == ZERO_WIDTH_JOINER ||
        ord == ZERO_WIDTH_NON_JOINER ||
        variation_selector?(ord) ||
        control_codepoint?(ord)
    end

    private def control_codepoint?(ord : Int32) : Bool
      (0x00..0x1F).includes?(ord) || (0x7F..0x9F).includes?(ord)
    end

    private def variation_selector?(ord : Int32) : Bool
      (0xFE00..0xFE0F).includes?(ord) || (0xE0100..0xE01EF).includes?(ord)
    end

    private def wide?(ord : Int32) : Bool
      return true if (0x1100..0x115F).includes?(ord)
      return true if (0x231A..0x231B).includes?(ord)
      return true if (0x2329..0x232A).includes?(ord)
      return true if (0x23E9..0x23EC).includes?(ord)
      return true if ord == 0x23F0 || ord == 0x23F3
      return true if (0x25FD..0x25FE).includes?(ord)
      return true if (0x2614..0x2615).includes?(ord)
      return true if (0x2648..0x2653).includes?(ord)
      return true if ord == 0x267F
      return true if ord == 0x2693
      return true if ord == 0x26A1
      return true if (0x26AA..0x26AB).includes?(ord)
      return true if (0x26BD..0x26BE).includes?(ord)
      return true if (0x26C4..0x26C5).includes?(ord)
      return true if ord == 0x26CE || ord == 0x26D4 || ord == 0x26EA
      return true if (0x26F2..0x26F3).includes?(ord)
      return true if ord == 0x26F5 || ord == 0x26FA || ord == 0x26FD
      return true if ord == 0x2705
      return true if (0x270A..0x270B).includes?(ord)
      return true if ord == 0x2728 || ord == 0x274C || ord == 0x274E
      return true if (0x2753..0x2755).includes?(ord)
      return true if ord == 0x2757
      return true if (0x2795..0x2797).includes?(ord)
      return true if ord == 0x27B0 || ord == 0x27BF
      return true if (0x2B1B..0x2B1C).includes?(ord)
      return true if ord == 0x2B50 || ord == 0x2B55
      return true if (0x2E80..0xA4CF).includes?(ord)
      return true if (0xAC00..0xD7A3).includes?(ord)
      return true if (0xF900..0xFAFF).includes?(ord)
      return true if (0xFE10..0xFE19).includes?(ord)
      return true if (0xFE30..0xFE6F).includes?(ord)
      return true if (0xFF00..0xFF60).includes?(ord)
      return true if (0xFFE0..0xFFE6).includes?(ord)
      return true if (0x1F300..0x1FAFF).includes?(ord)
      return true if (0x20000..0x2FFFD).includes?(ord)
      return true if (0x30000..0x3FFFD).includes?(ord)

      false
    end
  end
end
