class Curryable
  class ArgumentList
    def initialize(parameters, arguments)
      @parameters = parameters
      @arguments = arguments
    end

    attr_reader :parameters, :arguments
    private     :parameters, :arguments

    include Enumerable
    def each(&block)
      (positional + keyword).each(&block)
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

    # def satisfied?
    # end
    #
    # def outstanding
    # end
    #
    # def provided
    # end

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
