class Curryable
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

    def required_keywords
      list.select(&:keyword?).select(&:required?)
    end

    private

    def required_positional
      positional.select(&:required?)
    end

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
