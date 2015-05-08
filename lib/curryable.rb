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

  protected

  def enough_arguments?
    enough_positional_arguments? && enough_keyword_arguments?
  end

  def execute
    command_class.new(*arguments).call
  end

  private

  def combined_arguments(new_arguments)
    enough_positional_arguments? ?
      arguments.take(arity) + [provided_keyword_arguments.merge(new_arguments.first)] :
      arguments + new_arguments
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
