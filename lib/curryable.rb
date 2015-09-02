require "curryable/parameter_list"
require "curryable/argument_list"

class Curryable
  def initialize(command_class, arguments = nil)
    @command_class = command_class
    @arguments = arguments || default_argument_list
  end

  attr_reader :command_class, :arguments
  private     :command_class, :arguments

  def call(*new_arguments)
    new_with_arguments(arguments + new_arguments)
      .evaluate_if_fulfilled
  end

  def inspect
    "#<Curryable<%{command_class}>:0x%{hex_object_id} %{arguments}>" % {
      command_class: command_class.name,
      hex_object_id: object_id.<<(1).to_s(16),
      arguments: arguments.map(&:to_s).join(", "),
    }
  end

  protected

  def evaluate_if_fulfilled
    if arguments.fulfilled?
      evaluate
    else
      self
    end
  end

  private

  def evaluate
    command_class.new(*arguments.primitives).call
  end

  def new_with_arguments(new_arguments)
    self.class.new(command_class, new_arguments)
  end

  def parameters
    ParameterList.new(command_class.instance_method(:initialize).parameters)
  end

  def default_argument_list
    ArgumentList.new(parameters, [])
  end
end
