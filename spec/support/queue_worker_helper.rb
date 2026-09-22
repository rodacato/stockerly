# Liveness is read from the rows bin/jobs registers, so a spec that needs an
# attended queue registers one rather than stubbing the count.
module QueueWorkerHelper
  def register_queue_worker(name: "spec-worker-#{SecureRandom.hex(4)}")
    SolidQueue::Process.create!(kind: "Worker", name: name, pid: Process.pid,
                                hostname: "spec", last_heartbeat_at: Time.current)
  end
end

RSpec.configure do |config|
  config.include QueueWorkerHelper
end
