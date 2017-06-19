module EyeDiff
  class ThreadPool

    attr_accessor :mutex

    def initialize(size)
      @size = size
      @mutex = Mutex.new
      @jobs = Queue.new
      @pool = Array.new(@size) do |i|
        Thread.new do
          Thread.current[:id] = i
          catch(:exit) do
            loop do
              job, args = @jobs.pop
              job.call(*args)
            end
          end
        end
      end
    end

    def schedule(*args, &block)
      @jobs << [block, args]
    end

    def shutdown
      @size.times do
        schedule { throw :exit }
      end

      @pool.map(&:join)
    end

    def eop?
      @jobs.empty?
    end

    def cleanup
      @jobs.clear
      @pool.map(&:kill)
    end

  end
end
