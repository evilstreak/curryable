require "curryable/parameter_list"
require "curryable/argument_list"

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

    if curryable.arguments_fulfilled?
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
      arguments_for_inspection,
      ">",
    ].join
  end

  protected

  def arguments_fulfilled?
    better_arguments.fulfilled?
  end

  def execute
    command_class.new(*arguments).call
  end

  private

  def arguments_for_inspection
    better_arguments.map(&:to_s).join(", ")
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

  def required_keywords
    parameters.required_keywords.map(&:name)
  end

  def arity
    parameters.arity
  end

  def parameters
    ParameterList.new(command_class.instance_method(:initialize).parameters)
  end

  def better_arguments
    ArgumentList.new(parameters, arguments)
  end
end
