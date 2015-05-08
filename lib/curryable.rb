class Curryable
  def initialize(command_class, **arguments)
    @command_class = command_class
    @arguments = arguments
  end

  attr_reader :command_class, :arguments
  private     :command_class, :arguments

  def call(**new_arguments)
    combined_arguments = arguments.merge(new_arguments)
    curryable = self.class.new(command_class, combined_arguments)

    if curryable.enough_arguments?
      curryable.execute
    else
      curryable
    end
  end

  protected

  def enough_arguments?
    provided_keywords & required_keywords == required_keywords
  end

  def execute
    command_class.new(arguments).call
  end

  private

  def provided_keywords
    arguments.keys
  end

  def required_keywords
    parameters.map { |(_type, name)| name }
  end

  def parameters
    command_class.instance_method(:initialize).parameters
  end
end
