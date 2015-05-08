require "spec_helper"
require "curryable"

RSpec.describe Curryable do
  class CommandClass
    def initialize(a:, b:, c:)
      @a = a
      @b = b
      @c = c
    end

    def call
      $command_spy.call(a: @a, b: @b, c: @c)
    end
  end

  let(:a) { double(:a) }
  let(:b) { double(:b) }
  let(:c) { double(:c) }
  let(:command_spy) { spy }

  subject(:curryable) {
    Curryable.new(CommandClass)
  }

  before do
    $command_spy = command_spy
  end

  context "when all arguments are provided in one call" do
    it "executes the #call method of the command class" do
      curryable.call(a: a, b: b, c: c)

      expect(command_spy).to have_received(:call).with(a: a, b: b, c: c)
    end
  end

  context "when some arguments are provided" do
    it "does not execute the #call method of the command class" do
      curryable.call(a: a)

      expect(command_spy).not_to have_received(:call)
    end
  end
end
