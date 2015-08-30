class Curryable
  def initialize(command_class, *arguments)
    @command_class = command_class
    @arguments = arguments
  end

  attr_reader :command_class, :arguments
  private     :command_class, :arguments

  def call(*new_arguments)
    curryable = self.class.new(
      command_class,
      *combined_arguments(new_arguments)
    )

    if curryable.enough_arguments?
      curryable.execute
    else
      curryable
    end
  end

  def inspect
    [
      "#<Curryable",
      "<",
      command_class.name,
      ">",
      ":0x",
      object_id.<<(1).to_s(16),
      " ",
      parameters_for_inspection,
      ">",
    ].join
  end

  protected

  def enough_arguments?
    enough_positional_arguments? && enough_keyword_arguments?
  end

  def execute
    command_class.new(*arguments).call
  end

  private

  def parameters_for_inspection
    parameters_with_values.map(&:to_s).join(", ")
  end

  def positional_parameter_names
    positional_parameters.map(&:name)
  end

  def positional_parameters
    parameters.positional
  end

  def combined_arguments(new_arguments)
    combined = arguments + new_arguments

    positional = combined.take(arity)

    possible_keywords = combined.drop(arity)

    unless possible_keywords.all? { |arg| arg.is_a?(Hash) }
      excess_arg_count = combined.length

      raise ArgumentError.new(
        "wrong number of arguments (#{excess_arg_count} for #{arity})"
      )
    end

    keywords = possible_keywords.reduce(&:merge) || {}

    unknown_keywords = keywords.keys - required_keywords

    if unknown_keywords.any?
      plural = unknown_keywords.length > 1 ? "s" : ""

      raise ArgumentError.new(
        "unknown keyword#{plural}: #{unknown_keywords.join(", ")}"
      )
    end

    positional + [keywords].reject(&:empty?)
  end

  def enough_positional_arguments?
    arguments.length >= arity
  end

  def enough_keyword_arguments?
    provided_keywords & required_keywords == required_keywords
  end

  def provided_keywords
    provided_keyword_arguments.keys
  end

  def provided_keyword_arguments
    arguments.drop(arity).fetch(0, {})
  end

  def required_keywords
    parameters.required_keywords.map(&:name)
  end

  def arity
    parameters.arity
  end

  def parameters
    ParameterList.new(command_class.instance_method(:initialize).parameters)
  end

  def parameters_with_values
    ParametersWithValues.new(parameters, arguments)
  end

  class ParametersWithValues
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
        PositionalParameterWithValue.new(parameter, value)
      }
    end

    def keyword
      parameters.required_keywords.map { |parameter|
        KeywordParameterWithValue.new(
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
  end

  class ParameterWithValue
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

  class PositionalParameterWithValue < ParameterWithValue
    def to_s
      "#{name}=#{value.inspect}"
    end
  end

  class KeywordParameterWithValue < ParameterWithValue
    def to_s
      "#{name}:#{value.inspect}"
    end
  end

  class ParameterList
    def initialize(list)
      @raw_list = list
    end

    def arity
      required_positional.count
    end

    def positional
      list.select(&:positional?)
    end

    def required_positional
      positional.select(&:required?)
    end

    def required_keywords
      list.select(&:keyword?).select(&:required?)
    end

    private

    def list
      @list ||= @raw_list.map { |type, name| Parameter.new(type, name) }
    end

    class Parameter
      def initialize(type, name)
        @type = type
        @name = name
      end

      attr_reader :type, :name

      def required?
        type == :req || type == :keyreq
      end

      def positional?
        type == :req
      end

      def keyword?
        type == :keyreq
      end
    end
  end
end
