class Curryable
  class ArgumentList
    def initialize(parameters, primitive_list)
      @parameters = parameters

      pos, key = split_primitives(primitive_list)

      check_positional_within_arity(pos)
      check_for_unknown_keywords(key)

      @positional = extract_positional(pos)
      @keyword = extract_keyword(key)
    end

    attr_reader :parameters, :keyword, :positional
    private     :parameters, :keyword, :positional

    include Enumerable
    def each(&block)
      (positional + keyword).each(&block)
    end

    def primitives
      positional_values + [keyword_values].reject(&:empty?)
    end

    def fulfilled?
      all?(&:fulfilled?)
    end

    def +(new_values)
      if keyword.any?(&:fulfilled?) && new_values.map(&:class) == [Hash]
        combined = primitives.take(parameters.arity) +
          [
            primitives.drop(parameters.arity).fetch(0, {}).merge(new_values.first)
          ]
      else
        combined = primitives + new_values
      end

      self.class.new(parameters, combined)
    end

    private

    def positional_values
      positional.select(&:fulfilled?).map(&:value)
    end

    def keyword_values
      Hash[
        keyword
          .select(&:fulfilled?)
          .map { |argument| [ argument.name, argument.value ] }
      ]
    end

    def extract_positional(primitives)
      parameters.positional.map.with_index { |parameter, i|
        PositionalArgument.new(parameter, primitives.fetch(i, nothing))
      }
    end

    def extract_keyword(primitives)
      parameters.required_keywords.map { |parameter|
        KeywordArgument.new(
          parameter,
          primitives.fetch(parameter.name, nothing)
        )
      }
    end

    def nothing
      @nothing ||= SweetNothing.new
    end

    def split_primitives(primitive_list)
      if primitive_list.length == parameters.arity + 1 && primitive_list.last.is_a?(Hash)
        [primitive_list.take(parameters.arity), primitive_list.last]
      else
        [primitive_list, {}]
      end
    end

    def check_positional_within_arity(primitives)
      unless primitives.length <= parameters.arity
        raise ArgumentError.new(
          "wrong number of arguments (#{primitives.length} for #{parameters.arity})"
        )
      end
    end

    def check_for_unknown_keywords(primitives)
      unknown_keywords = primitives.keys - parameters.required_keywords.map(&:name)

      if unknown_keywords.any?
        plural = unknown_keywords.length > 1 ? "s" : ""

        raise ArgumentError.new(
          "unknown keyword#{plural}: #{unknown_keywords.join(", ")}"
        )
      end
    end

    class SweetNothing
      def inspect
        ""
      end
    end

    class Argument
      def initialize(parameter, value)
        @parameter = parameter
        @value = value
      end

      attr_reader :parameter, :value
      private     :parameter

      def name
        parameter.name
      end

      def fulfilled?
        !(SweetNothing === value)
      end
    end

    class PositionalArgument < Argument
      def to_s
        "#{name}=#{value.inspect}"
      end
    end

    class KeywordArgument < Argument
      def to_s
        "#{name}:#{value.inspect}"
      end
    end
  end
end
