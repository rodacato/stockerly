require "rails_helper"

RSpec.describe SimpleUseCase do
  describe ".call" do
    let(:read_use_case) do
      Class.new(described_class) do
        def call(value:)
          { doubled: value * 2 }
        end
      end
    end

    let(:no_failure_method) do
      Class.new(described_class) do
        def call(predicate:)
          predicate.even?
        end
      end
    end

    it "delegates to new.call with positional and keyword args" do
      result = read_use_case.call(value: 5)
      expect(result).to eq(doubled: 10)
    end

    it "returns whatever the subclass returns (no Result wrapping)" do
      expect(no_failure_method.call(predicate: 4)).to be true
      expect(no_failure_method.call(predicate: 5)).to be false
    end

    it "lets exceptions propagate (no rescue or Result conversion)" do
      raiser = Class.new(described_class) do
        def call
          raise ActiveRecord::RecordNotFound, "missing"
        end
      end

      expect { raiser.call }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
