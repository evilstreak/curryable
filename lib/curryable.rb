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
    arguments.fulfilled?
  end

  def execute
    command_class.new(*arguments.primitives).call
  end

  private

  def arguments_for_inspection
    arguments.map(&:to_s).join(", ")
  end

  def parameters
    ParameterList.new(command_class.instance_method(:initialize).parameters)
  end

  def default_argument_list
    ArgumentList.new(parameters, [])
  end
end
