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
    [
      positional_parameters_for_inspection,
      keyword_parameters_for_inspection,
    ].reject(&:empty?).join(", ")
  end

  class SweetNothing
    def inspect
      ""
    end
  end

  def positional_parameters_for_inspection
    nothings = [SweetNothing.new] * positional_parameters.length
    positional_parameter_names.zip(arguments + nothings).map { |name, value|
      "#{name.to_s}=#{value.inspect}"
    }.join(", ")
  end

  def keyword_parameters_for_inspection
    required_keywords
      .map { |name|
        [
          name,
          provided_keyword_arguments.fetch(name, SweetNothing.new)
        ]
      }
      .map { |name, value|
        "#{name.to_s}:#{value.inspect}"
      }
      .join(", ")
  end

  def positional_parameter_names
    positional_parameters.map(&:last)
  end

  def positional_parameters
    parameters.select { |(type, _name)| type == :req }
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
    parameters
      .select { |(type, _name)| type == :keyreq }
      .map { |(_type, name)| name }
  end

  def arity
    parameters.count { |(type, _name)| type == :req }
  end

  def parameters
    command_class.instance_method(:initialize).parameters
  end
end
