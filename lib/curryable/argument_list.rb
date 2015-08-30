class Curryable
  class ArgumentList
    def initialize(parameters, arguments)
      @parameters = parameters
      @arguments = arguments
    end

    attr_reader :parameters, :arguments
    private     :parameters, :arguments

    # TODO Reevaluate this. (says @bestie)
    include Enumerable
    def each(&block)
      (positional + keyword).each(&block)
    end

    # TODO This probably needs looking at too.
    def primitive
      @arguments
    end

    def positional
      nothings = [nothing] * parameters.arity

      parameters.positional.zip(arguments + nothings).map { |parameter, value|
        PositionalArgument.new(parameter, value)
      }
    end

    def keyword
      parameters.required_keywords.map { |parameter|
        KeywordArgument.new(
          parameter,
          provided_keyword_arguments.fetch(parameter.name, nothing)
        )
      }
    end

    def provided_keyword_arguments
      arguments.drop(parameters.arity).fetch(0, {})
    end

    def fulfilled?
      all?(&:fulfilled?)
    end

    def +(new_values)
      combined = primitive + new_values

      positional = combined.take(parameters.arity)

      possible_keywords = combined.drop(parameters.arity)

      unless possible_keywords.all? { |arg| arg.is_a?(Hash) }
        excess_arg_count = combined.length

        raise ArgumentError.new(
          "wrong number of arguments (#{excess_arg_count} for #{parameters.arity})"
        )
      end

      keywords = possible_keywords.reduce(&:merge) || {}

      unknown_keywords = keywords.keys - parameters.required_keywords.map(&:name)

      if unknown_keywords.any?
        plural = unknown_keywords.length > 1 ? "s" : ""

        raise ArgumentError.new(
          "unknown keyword#{plural}: #{unknown_keywords.join(", ")}"
        )
      end

      self.class.new(
        parameters,
        positional + [keywords].reject(&:empty?),
      )
    end

    private

    def nothing
      @nothing ||= SweetNothing.new
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
