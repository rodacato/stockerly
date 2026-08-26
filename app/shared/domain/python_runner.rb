require "open3"

# Runs a bundled Python script and parses its JSON output.
#
# It exists because Yahoo blocks HTTP clients by TLS fingerprint, and the only
# maintained way through is a Python library that impersonates a browser. The
# script is addressed by name from lib/python, arguments are passed as an argv
# array so no shell is involved, and a script that hangs is killed rather than
# holding a worker.
class PythonRunner
  include Dry::Monads[:result]

  SCRIPT_DIR = Rails.root.join("lib/python")
  DEFAULT_TIMEOUT = 25
  SAFE_ARGUMENT = /\A[A-Za-z0-9.^\-_=*]{1,32}\z/

  def self.call(script, *args, timeout: DEFAULT_TIMEOUT)
    new.call(script, *args, timeout: timeout)
  end

  def call(script, *args, timeout: DEFAULT_TIMEOUT)
    path = SCRIPT_DIR.join(script)
    return Failure([ :not_supported, "No such script: #{script}" ]) unless path.exist?

    arguments = args.map(&:to_s)
    invalid = arguments.reject { |arg| arg.match?(SAFE_ARGUMENT) }
    return Failure([ :invalid_request, "Unsafe argument: #{invalid.first}" ]) if invalid.any?

    execute(path.to_s, arguments, timeout)
  end

  private

  def execute(path, arguments, timeout)
    stdout, stderr, status = capture(path, arguments, timeout)
    return Failure([ :timeout, "#{File.basename(path)} exceeded #{timeout}s" ]) if status.nil?
    return failure_from(stderr) unless status.success?

    Success(JSON.parse(stdout))
  rescue JSON::ParserError => e
    Failure([ :gateway_error, "Unparseable output: #{e.message}" ])
  rescue Errno::ENOENT
    Failure([ :not_supported, "Python is not available in this environment" ])
  end

  def capture(path, arguments, timeout)
    Open3.popen3(python_bin, path, *arguments) do |stdin, out, err, wait_thr|
      stdin.close
      readers = [ Thread.new { out.read }, Thread.new { err.read } ]

      if wait_thr.join(timeout).nil?
        Process.kill("KILL", wait_thr.pid)
        readers.each(&:kill)
        next [ nil, nil, nil ]
      end

      [ readers[0].value, readers[1].value, wait_thr.value ]
    end
  end

  # The script reports its own failure kind, so a missing symbol stays distinct
  # from a broken interpreter.
  def failure_from(stderr)
    parsed = JSON.parse(stderr.to_s)
    Failure([ parsed["error"].to_s.presence&.to_sym || :gateway_error, parsed["message"].to_s ])
  rescue JSON::ParserError
    Failure([ :gateway_error, stderr.to_s.lines.last.to_s.strip.presence || "Python script failed" ])
  end

  def python_bin
    ENV["PYTHON_BIN"].presence || "python3"
  end
end
