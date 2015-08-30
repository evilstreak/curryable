require "curryable/parameter_list"
require "curryable/argument_list"

class Curryable
  # TODO we could pass an ArgumentList instead of a splat here
  def initialize(command_class, arguments = nil)
    @command_class = command_class
    @arguments = arguments || default_argument_list
  end

  attr_reader :command_class, :arguments
  private     :command_class, :arguments

  def call(*new_arguments)
    curryable = self.class.new(
      command_class,
      arguments + new_arguments,
    )

    if curryable.arguments_fulfilled?
      curryable.execute
    else
      curryable
    end
  end

  def inspect
    "#<Curryable<%{command_class}>:0x%{hex_object_id} %{arguments}>" % {
      command_class: command_class.name,
      hex_object_id: object_id.<<(1).to_s(16),
      arguments: arguments.map(&:to_s).join(", "),
    }
  end

  protected

  def arguments_fulfilled?
    arguments.fulfilled?
  end

  def execute
    command_class.new(*arguments.primitives).call
  end

  private

  def positional_parameter_names
    positional_parameters.map(&:name)
  end

  def positional_parameters
    parameters.positional
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

  def default_argument_list
    ArgumentList.new(parameters, [])
  end
end
