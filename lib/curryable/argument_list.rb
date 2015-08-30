class Curryable
  class ArgumentList
    def initialize(parameters, primitive_list)
      @parameters = parameters
      check_positional_within_arity(primitive_list)
      @positional = extract_positional(primitive_list)
      check_for_unknown_keywords(primitive_list)
      @keyword = extract_keyword(primitive_list)
    end

    attr_reader :parameters, :keyword, :positional
    private     :parameters, :keyword, :positional

    # TODO Reevaluate this. (says @bestie)
    include Enumerable
    def each(&block)
      (positional + keyword).each(&block)
    end

    # TODO This probably needs looking at too.
    def primitives
      positional.select(&:fulfilled?).map(&:value) +
        [Hash[keyword.select(&:fulfilled?).map { |p| [ p.name, p.value ] }]].reject(&:empty?)
    end

    def extract_positional(primitives)
      nothings = [nothing] * parameters.arity

      parameters.positional.map.with_index { |parameter, i|
        PositionalArgument.new(parameter, primitives.fetch(i, nothing))
      }
    end

    def extract_keyword(primitives)
      provided_keyword_arguments  = primitives.drop(parameters.arity).fetch(0, {})

      parameters.required_keywords.map { |parameter|
        KeywordArgument.new(
          parameter,
          provided_keyword_arguments.fetch(parameter.name, nothing)
        )
      }
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

    def nothing
      @nothing ||= SweetNothing.new
    end

    def check_positional_within_arity(primitives)
      possible_keywords = primitives.drop(parameters.arity)

      unless possible_keywords.empty? || possible_keywords.map(&:class) == [Hash]
        raise ArgumentError.new(
          "wrong number of arguments (#{primitives.length} for #{parameters.arity})"
        )
      end
    end

    def check_for_unknown_keywords(primitives)
      given_keywords = primitives.drop(parameters.arity).fetch(0, {}).keys
      unknown_keywords = given_keywords - parameters.required_keywords.map(&:name)
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
