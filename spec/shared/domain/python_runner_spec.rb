require "rails_helper"

# Runs the real subprocess on purpose: probe.py has no dependency and no
# network, which is what makes exercising the runner for real safe.
RSpec.describe PythonRunner, :real_subprocess do
  describe ".call" do
    # probe.py has no third-party dependency and touches no network, so this
    # exercises the runner itself rather than whatever the image has installed.
    it "parses the JSON a script prints" do
      result = described_class.call("probe.py")

      expect(result).to be_success
      expect(result.value!).to include("python")
    end

    it "refuses a script that is not bundled" do
      expect(described_class.call("not_here.py").failure[0]).to eq(:not_supported)
    end

    # Arguments reach argv directly rather than a shell, and anything that is
    # not ticker-shaped is refused before it gets that far.
    it "refuses an argument that is not ticker-shaped" do
      result = described_class.call("probe.py", "AAPL; rm -rf /")

      expect(result.failure[0]).to eq(:invalid_request)
      expect(result.failure[1]).to include("Unsafe argument")
    end

    it "reports a missing interpreter as unsupported rather than crashing" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("PYTHON_BIN").and_return("/nonexistent/python")

      expect(described_class.call("probe.py").failure[0]).to eq(:not_supported)
    end

    it "keeps the failure kind a script reports on stderr" do
      result = described_class.call("yahoo.py", "quote")

      expect(result.failure[0]).to eq(:invalid_request)
      expect(result.failure[1]).to include("usage")
    end
  end
end
