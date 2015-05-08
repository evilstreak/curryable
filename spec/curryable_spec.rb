require "spec_helper"
require "curryable"

RSpec.describe Curryable do
  class CommandClass
    def initialize(a:, b:, spy:)
      @a = a
      @b = b
      @spy = spy
    end

    def call
      @spy.call(a: @a, b: @b)
    end
  end

  let(:a) { double(:a) }
  let(:b) { double(:b) }
  let(:command_spy) { spy }

  subject(:curryable) {
    Curryable.new(CommandClass)
  }

  context "when all arguments are provided in one call" do
    it "executes the #call method of the command class" do
      curryable.call(a: a, b: b, spy: command_spy)

      expect(command_spy).to have_received(:call).with(a: a, b: b)
    end
  end
end
