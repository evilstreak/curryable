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
      raise ArgumentError.new(
        "unknown keyword: #{unknown_keywords.first}"
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
