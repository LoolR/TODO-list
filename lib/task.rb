class Task
  attr_reader :id, :description
  attr_accessor :done, :deadline, :date

  def initialize(id, description, done, deadline)
    @id = id
    @description = description
    @done = done
    @deadline = deadline
    @date = Time.now.strftime("%Y-%m-%d").to_s
  end

  def done? #car done est le seul qui change
    done
  end


end
