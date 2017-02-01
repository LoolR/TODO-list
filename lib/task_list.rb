require_relative 'task'
require 'date'
class TaskList
  QUIT = 'quit'

  def initialize(input, output)
    @input = input
    @output = output

    @tasks = {}

  end

  def run
    while true
      @output.print('> ')
      @output.flush #forces @output to appear immediatly

      command = @input.readline.strip  #"\tgoodbye\r\n".strip   #=> "goodbye"
      break if command == QUIT

      execute(command)
    end
  end

  private
#check the part of the command entered before the first space
  def execute(command_line)
    #the first part of command_line is stored in command and the second is is rest
    command, rest = command_line.split(/ /, 2)
    case command
      when 'show' #display tasks by projects and all the properties of each task
        show
      when 'add'  #add a new task or project, btw..A project can contain many tasks
        add rest
      when 'check' #mark the task entered as checked
        check rest
      when 'uncheck' #mark the task entered as unchecked
        uncheck rest
      when 'help' #check the existing commands and there format
        help
      when 'deadline' # adding the ability to precise a deadline for a task already existing, syntax: deadline id_task date_deadline
        deadline rest
      when 'today' # adding the ability to display all tasks which deadline is today
        today
      when 'delete' #adding the ability to delete a task, syntax: delete id_task
        delete rest
      when 'view' #displays tasks by date or deadline or project depending on input, syntax: view by date||view by deadline||view by project
        view rest
      else
        error command
    end
  end


  def view(rest)
    by, argu = rest.split(/ /,2) # I ignore the word 'by'
    #checking wether the input after 'by'is 'date'|| 'deadline'|| 'project'
    if argu == "date"
      @tasks.each do |project_name, project_tasks|
        project_tasks.group_by{|task| task.date}.each do |key, group| puts key

        group.each{|item|
          puts item.description}
        end
      end
    end
    if argu == "deadline"
      @tasks.each do |project_name, project_tasks|
        project_tasks.group_by{|task| task.deadline }.each do |key, group| puts key
        group.each{|item|
          puts item.description}
        end
      end
    end
    if argu == "project"
      @tasks.each do |project_name, project_tasks|
        @output.puts project_name
        project_tasks.each do |task|
          @output.puts('    '+ task.description)
        end
      end
    end
  end

#delete a task by id
  def delete(id_string)
    id = id_string.to_i
    @tasks.each do |project_name, project_tasks|
      project_tasks.each do |task|
        project_tasks.delete_if {task.id == id_string.to_i}
      end
    end
  end

#display tasks which deadline is today
  def today
    tod = Time.now.strftime("%Y-%m-%d")
    @tasks.each do |project_name, project_tasks|
      project_tasks.each do |task|
        if task.deadline.to_s == tod
          puts task.description
        end
      end
    end
  end

#enter a deadline for an existing task, format or the deadline must be Month/Day/Year
  def deadline (rest)
    id_string, datedl = rest.split(/ /,2)
    id = id_string.to_i
    #checking id the deadline entered is a valid date
    begin
      dl = Date.strptime(datedl, "%m/%d/%Y")
      #code using date goes here
      task = @tasks.collect { |project_name, project_tasks|
        project_tasks.find { |t| t.id == id }
      }.reject(&:nil?).first

      if task.nil?
        @output.printf("Could not find a task with an ID of %d.\n", id)
        return
      end
      task.deadline = dl
        #checking if the deadline is not a valid date
    rescue ArgumentError
      #code dealing with an invalid date goes here
      @output.printf('The deadline entered is not a valid date!!')
    end
    #adding the deadline to the same task(same description)if it exists in more than one project!
    @tasks.each { |project_name, project_tasks|
      project_tasks.each { |task|
        if task.id == id
          @tasks.each do |project_name, project_tasks|
            project_tasks.each do |t|
              if t.description == task.description
                t.deadline = task.deadline
              end
            end
          end
        end
      }

    }
  end

#display tasks by projects and all the properties of each task
  def show
    @tasks.each do |project_name, project_tasks|
      @output.puts project_name
      project_tasks.each do |task|
        @output.printf("  [%c] %d: %s : %s \n", (task.done? ? 'x' : ' '), task.id, task.description, task.deadline)
      end
      @output.puts
    end
  end

#adding a project or a task within a project
  def add(command_line)
    subcommand, rest = command_line.split(/ /, 2)
    #checking wether the second word after command 'add' is 'project' || 'task'
    if subcommand == 'project'
      add_project rest
    elsif subcommand == 'task'
      project, description, deadline = rest.split(/ /, 3)
      add_task project, description, deadline
    end
  end

#if the command entered is>add project proj_name
  def add_project(name)
    @tasks[name] = []
  end

#if the command entered is>add task proj_name task_name
  def add_task(project, description, deadline)
    project_tasks = @tasks[project]
    if project_tasks.nil?
      @output.printf("Could not find a project with the name \"%s\".\n", project)
      return
    end
    t = Task.new(next_id, description, false, deadline)
    project_tasks << t
    #checking if the task newly created already exists in another project and import its properties to the new one 't'
    @tasks.each do |project_name, project_tasks|
      project_tasks.each do |task|
        if task.description == t.description
          t.done= task.done
          t.date = task.date
        end
      end
    end
  end

#Mark the task as done by setting its property done to true
  def check(id_string)
    set_done(id_string, true)
    #checking all other tasks with same name/description as the newly checked task which id is id_string
    id = id_string.to_i
    @tasks.each { |project_name, project_tasks|
      project_tasks.each { |task|
        if task.id == id
          @tasks.each do |project_name, project_tasks|
            project_tasks.each do |t|
              if t.description == task.description
                set_done(t.id.to_s, true)
              end
            end
          end
        end
      }
    }
  end

#Mark the task as undone by setting its property done to false
  def uncheck(id_string)
    set_done(id_string, false)
    #checking all other tasks with same name/description as the newly unchecked task which id is 'id_string'
    id = id_string.to_i
    @tasks.each { |project_name, project_tasks|
      project_tasks.each { |task|
        if task.id == id
          # puts 'here1'
          @tasks.each do |project_name, project_tasks|
            project_tasks.each do |t|
              if t.description == task.description
                set_done(t.id.to_s, false)
                # puts 'here2'
                # puts task.done
                # puts t.done
              end
            end
          end
        end
      }

    }
  end

  def set_done(id_string, done)
    id = id_string.to_i

    task = @tasks.collect { |project_name, project_tasks|
      project_tasks.find { |t| t.id == id }
    }.reject(&:nil?).first

    if task.nil?
      @output.printf("Could not find a task with an ID of %d.\n", id)
      return
    end

    task.done = done
  end

  def help
    @output.puts('Commands:')
    @output.puts('  show')
    @output.puts('  add project <project name>')
    @output.puts('  add task <project name> <task description>')
    @output.puts('  check <task ID>')
    @output.puts('  uncheck <task ID>')
    @output.puts('  deadline <ID Date>')
    @output.puts('  today')
    @output.puts('  view by deadline')
    @output.puts('  view by date')
    @output.puts('  view by project')
    @output.puts()
  end

  def error(command)
    @output.printf("I don't know what the command \"%s\" is.\n", command)
  end

  def next_id
    @last_id ||= 0
    @last_id += 1
    @last_id
  end


  if __FILE__ == $0
    TaskList.new($stdin, $stdout).run
  end
end