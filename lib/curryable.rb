class Curryable
  def initialize(command_class)
    @command_class = command_class
  end

  attr_reader :command_class
  private     :command_class

  def call(**arguments)
    command_class.new(arguments).call
  end
end
