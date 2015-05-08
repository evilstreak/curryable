require "spec_helper"
require "curryable"

RSpec.describe "Mixed required arguments" do
  class MixedRequiredCommandClass
    def initialize(a, b, c:, d:)
      @a = a
      @b = b
      @c = c
      @d = d
    end

    def call
      $command_spy.call(a: @a, b: @b, c: @c, d: @d)
    end
  end

  let(:a) { double(:a) }
  let(:b) { double(:b) }
  let(:c) { double(:c) }
  let(:d) { double(:d) }
  let(:command_spy) { spy }

  subject(:curryable) {
    Curryable.new(MixedRequiredCommandClass)
  }

  let(:return_value) { double(:return_value) }

  before do
    $command_spy = command_spy

    allow(command_spy).to receive(:call).and_return(return_value)
  end

  context "when all arguments are provided in one call" do
    it "executes the #call method of the command class" do
      curryable.call(a, b, c: c, d: d)

      expect(command_spy).to have_received(:call).with(a: a, b: b, c: c, d: d)
    end

    it "returns the value returned by the command class" do
      result = curryable.call(a, b, c: c, d: d)

      expect(result).to be(return_value)
    end
  end

  context "when some arguments are provided" do
    it "does not execute the #call method of the command class" do
      curryable.call(a)

      expect(command_spy).not_to have_received(:call)
    end

    it "returns a Curryable" do
      expect(
        curryable.call(a)
      ).to be_a(Curryable)
    end
  end

  context "when arguments are provided in more than one call" do
    it "executes once with all arguments" do
      curryable
        .call(a)
        .call(b, c: c)
        .call(d: d)

      expect(command_spy).to have_received(:call).with(a: a, b: b, c: c, d: d)
    end

    it "returns the value returned by the command class" do
      result = curryable
        .call(a)
        .call(b, c: c)
        .call(d: d)

      expect(result).to be(return_value)
    end
  end

  context "when too many positional arguments are provided" do
    it "raises ArgumentError" do
      expect {
        curryable.call(a, b, c)
      }.to raise_error(ArgumentError, "wrong number of arguments (3 for 2)")
    end
  end
end
