module CRT::Ansi
  module Graphemes
    extend self

    ZERO_WIDTH_JOINER = 0x200D

    def each(text : String, &) : Nil
      return if text.empty?

      reader = Char::Reader.new(text)
      first_char = reader.current_char

      cluster = String::Builder.new
      cluster << first_char

      previous = first_char
      previous_was_zwj = previous.ord == ZERO_WIDTH_JOINER
      regional_count = regional_indicator?(previous) ? 1 : 0

      while reader.has_next?
        char = reader.next_char
        ord = char.ord

        join_cluster = false
        join_cluster ||= previous_was_zwj
        join_cluster ||= ord == ZERO_WIDTH_JOINER
        join_cluster ||= char.mark?
        join_cluster ||= variation_selector?(ord)
        join_cluster ||= emoji_modifier?(ord)
        join_cluster ||= regional_indicator_pair?(previous, char, regional_count)

        if join_cluster
          cluster << char
        else
          yield cluster.to_s
          cluster = String::Builder.new
          cluster << char
          regional_count = 0
        end

        if regional_indicator?(char)
          regional_count += 1
        else
          regional_count = 0
        end

        previous_was_zwj = ord == ZERO_WIDTH_JOINER
        previous = char
      end

      yield cluster.to_s
    end

    private def variation_selector?(ord : Int32) : Bool
      (0xFE00..0xFE0F).includes?(ord) || (0xE0100..0xE01EF).includes?(ord)
    end

    private def emoji_modifier?(ord : Int32) : Bool
      (0x1F3FB..0x1F3FF).includes?(ord)
    end

    private def regional_indicator?(char : Char) : Bool
      (0x1F1E6..0x1F1FF).includes?(char.ord)
    end

    private def regional_indicator_pair?(previous : Char, current : Char, regional_count : Int32) : Bool
      regional_indicator?(previous) && regional_indicator?(current) && regional_count.odd?
    end
  end
end
