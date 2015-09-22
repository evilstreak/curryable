require "spec_helper"
require "curryable"

RSpec.describe "Required keyword arguments" do

  command_spy = nil

  Curryable::TestClasses ||= Module.new
  Curryable::TestClasses::RequiredKeywordCommandClass = Class.new do
    define_method(:initialize) do |a:, b:, c:|
      @a = a
      @b = b
      @c = c
    end

    define_method(:call) do
      command_spy.call(a: @a, b: @b, c: @c)
    end
  end

  let(:a) { double(:a) }
  let(:b) { double(:b) }
  let(:c) { double(:c) }

  subject(:curryable) {
    Curryable.new(Curryable::TestClasses::RequiredKeywordCommandClass)
  }

  let(:return_value) { double(:return_value) }

  before do
    command_spy = spy

    allow(command_spy).to receive(:call).and_return(return_value)
  end

  context "when no arguments are provided" do
    it "can be inspected to show all arguments that must be provided" do
      expect(curryable.inspect).to match(
        %r{#<Curryable<Curryable::TestClasses::RequiredKeywordCommandClass>:0x[0-9a-f]{12} a:, b:, c:>}
      )
    end
  end

  context "when all arguments are provided in one call" do
    it "executes the #call method of the command class" do
      curryable.call(a: a, b: b, c: c)

      expect(command_spy).to have_received(:call).with(a: a, b: b, c: c)
    end

    it "returns the value returned by the command class" do
      result = curryable.call(a: a, b: b, c: c)

      expect(result).to be(return_value)
    end
  end

  context "when some arguments are provided" do
    subject(:partially_curried) {
      curryable.call(b: b)
    }

    it "does not execute the #call method of the command class" do
      partially_curried

      expect(command_spy).not_to have_received(:call)
    end

    it "returns a Curryable" do
      expect(partially_curried).to be_a(Curryable)
    end

    it "can be inspected to show which arguments have been provided and their values" do
      expect(partially_curried.inspect).to match(
        %r{#<Curryable<Curryable::TestClasses::RequiredKeywordCommandClass>:0x[0-9a-f]{12} a:, b:#<RSpec::Mocks::Double:0x[0-9a-f]{12} @name=:b>, c:>}
      )
    end
  end

  context "when arguments are provided in more than one call" do
    it "executes once with all arguments" do
      curryable
        .call(a: a)
        .call(b: b, c: c)

      expect(command_spy).to have_received(:call).with(a: a, b: b, c: c)
    end

    it "returns the value returned by the command class" do
      result = curryable
        .call(a: a)
        .call(b: b, c: c)

      expect(result).to be(return_value)
    end
  end
end
