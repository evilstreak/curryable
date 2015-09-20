require "spec_helper"
require "curryable"

RSpec.describe "Mixed required arguments" do

  command_spy = nil

  Curryable::TestClasses ||= Module.new
  Curryable::TestClasses::MixedRequiredCommandClass = Class.new do
    define_method(:initialize) do |a, b, c:, d:|
      @a = a
      @b = b
      @c = c
      @d = d
    end

    define_method(:call) do
      command_spy.call(a: @a, b: @b, c: @c, d: @d)
    end
  end

  let(:a) { double(:a) }
  let(:b) { double(:b) }
  let(:c) { double(:c) }
  let(:d) { double(:d) }

  subject(:curryable) {
    Curryable.new(Curryable::TestClasses::MixedRequiredCommandClass)
  }

  let(:return_value) { double(:return_value) }

  before do
    command_spy = spy

    allow(command_spy).to receive(:call).and_return(return_value)
  end

  context "when no arguments are provided" do
    it "can be inspected to show all arguments that must be provided" do
      expect(curryable.inspect).to match(
        %r{#<Curryable<Curryable::TestClasses::MixedRequiredCommandClass>:0x[0-9a-f]{12} a=, b=, c:, d:>}
      )
    end
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
    subject(:partially_curried) {
      curryable.call(a)
    }

    it "does not execute the #call method of the command class" do
      partially_curried

      expect(command_spy).not_to have_received(:call)
    end

    it "returns a Curryable" do
      expect(
        partially_curried
      ).to be_a(Curryable)
    end

    it "can be inspected to show which arguments have been provided and their values" do
      expect(partially_curried.inspect).to match(
        %r{#<Curryable<Curryable::TestClasses::MixedRequiredCommandClass>:0x[0-9a-f]{12} a=#<RSpec::Mocks::Double:0x[0-9a-f]{12} @name=:a>, b=, c:, d:>}
      )
    end
  end

  context "when some arguments are provided in more than one call" do
    subject(:partially_curried) {
      curryable
        .call(a)
        .call(b, c: c)
    }

    it "does not execute the #call method of the command class" do
      partially_curried

      expect(command_spy).not_to have_received(:call)
    end

    it "returns a Curryable" do
      expect(
        partially_curried
      ).to be_a(Curryable)
    end

    it "can be inspected to show which arguments have been provided and their values" do
      expect(partially_curried.inspect).to match(
        %r{#<Curryable<Curryable::TestClasses::MixedRequiredCommandClass>:0x[0-9a-f]{12} a=#<RSpec::Mocks::Double:0x[0-9a-f]{12} @name=:a>, b=#<RSpec::Mocks::Double:0x[0-9a-f]{12} @name=:b>, c:#<RSpec::Mocks::Double:0x[0-9a-f]{12} @name=:c>, d:>}
      )
    end
  end

  context "when all arguments are provided in more than one call" do
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

  context "when positional arguments are provided after keywords" do
    it "raises ArgumentError" do
      expect {
        curryable
          .call(a, b, c: c)
          .call(d)
      }.to raise_error(ArgumentError, "wrong number of arguments (4 for 2)")
    end
  end

  context "when an unknown keyword is provided" do
    it "raises ArgumentError" do
      expect {
        curryable
          .call(a, b, c: c)
          .call(e: "is an unknown keyword")
      }.to raise_error(ArgumentError, "unknown keyword: e")
    end
  end

  context "when multiple unknown keywords are provided" do
    it "raises ArgumentError" do
      expect {
        curryable
          .call(a, b, c: c)
          .call(
            e: "is an unknown keyword",
            f: "so is f",
          )
      }.to raise_error(ArgumentError, "unknown keywords: e, f")
    end
  end
end
