require 'digest\sha1'

class ObjectStore
  COMMIT_ERROR = 'Nothing to commit, working directory clean.'
  COMMIT_SUCCESS = "%s\n\t%d objects changed"
  ADD_SUCCESS = "Added %s to stage."
  HASH_MISSING = "Commit %s does not exist."
  PENDING_REMOVAL = "Added %s for removal."
  HEAD_AT = "HEAD is now at %s."
  NO_COMMITS = "Branch %s does not have any commits yet."
  COMMIT_LOG_PATTERN = "Commit %s\nDate: %s\n\n\t%s\n\n"
  NOT_COMMITED = "Object %s is not committed."
  FOUND = "Found object %s."

  attr_accessor :branches
  attr_accessor :current_branch

  def self.init(&block)
    return new() unless block

    me = new()
    me.instance_eval &block
    me
  end

  def initialize()
      @current_branch = Branch.new('master')
      @branches = [@current_branch]
  end

  def branch()
    @branch_operator = BranchManager.new(self) if not @branch_operator
    @branch_operator
  end

  def add(name, object)
    @current_branch.pending[name] = object
    OperationResult.new(ADD_SUCCESS % [name], true, object)
  end

  def commit(message)
    return OperationResult.new(COMMIT_ERROR, false) if @current_branch.pending.empty?

    object_count = @current_branch.pending.size
    commit = Commit.new(message, @current_branch.pending)
    @current_branch.commits << commit
    @current_branch.pending.clear

    OperationResult.new(COMMIT_SUCCESS % [message, object_count], true, commit)
  end

  def get(name)
    return OperationResult.new(NOT_COMMITED % name, false) if @current_branch.commits.empty?

    object = @current_branch.commits.last.actions[name] if @current_branch.commits.last.actions.has_key?(name)

    return OperationResult.new(NOT_COMMITED % name, false) if not object
    OperationResult.new(FOUND % name, true, object)
  end

  def remove(name)
    return OperationResult.new(NOT_COMMITED % name, true) if @current_branch.commits.empty?

    if (@current_branch.commits.last.actions.has_key?(name))
      @current_branch.commits.last.actions.delete(name)
      OperationResult.new(PENDING_REMOVAL % name, false)
    else
      OperationResult.new(NOT_COMMITED % name, true)
    end
  end

  def checkout(hash)
    return OperationResult.new(HASH_MISSING % hash, false) if @current_branch.commits.all? { |c| c.hash != hash}

    target = @current_branch.commits.select { |c| c.hash == hash }.first
    index = @current_branch.commits.index(target)
    @current_branch.commits = @current_branch.commits[0..index]

    return OperationResult.new(HEAD_AT % hash, true, @current_branch.commits.last)
  end

  def log()
    return OperationResult.new(NO_COMMITS % @current_branch.name, false) if @current_branch.commits.empty?

    commits_string = ""
    @current_branch.commits.reverse_each do |c|
      commits_string += COMMIT_LOG_PATTERN % [c.hash, c.date.strftime('%a %b %-d %H:%M %Y %z'), c.message]
    end

    commits_string.strip!
    OperationResult.new(commits_string, true)
  end

  def head()
    return OperationResult.new(NO_COMMITS % @current_branch.name, false) if @current_branch.commits.empty?

      last = @current_branch.commits.last
      OperationResult.new("#{last.message}", true, last)
  end
end

class OperationResult
  attr_reader :message
  attr_reader :result

  def initialize(message, success, result = nil)
    @message = message
    @success = success
    @result = result
  end

  def success?()
    @success
  end

  def error?()
    not success?
  end
end

class Change
  attr_reader :type
  attr_reader :value

  def initialize(type, value)
    @type = type
    @value = value
  end
end

class Commit
  attr_reader :message
  attr_reader :actions
  attr_reader :hash
  attr_reader :date

  def initialize(message, actions)
    @message = message
    @actions = actions.dup
    @date = Time.now
    @hash = Digest::SHA1.hexdigest "#{@date.strftime('%a %b %-d %H:%M %Y %z')}#{message}"
  end

  def objects()
    @actions.values
  end
end

class Branch
  attr_accessor :pending
  attr_accessor :commits
  attr_reader :name

  def initialize(branch_name)
      @pending = {}
      @objects = {}
      @commits = []
      @name = branch_name
  end
end

class BranchManager
  EXISTS = "Branch %s already exists."
  CREATED = "Created branch %s."
  DOES_NOT_EXIST = "Branch %s does not exist."
  SWITCHED_TO = "Switched to branch %s."
  REMOVED = "Removed branch %s"


  def initialize(repo)
    @repo = repo
  end

  def create(name)
    return OperationResult.new(EXISTS % name, false) if @repo.branches.any? { |b| b.name == name }

    @repo.branches << Branch.new(name, @repo.current_branch.commits)
    OperationResult.new(CREATED % name, true)
  end

  def checkout(name)
    return OperationResult.new(DOES_NOT_EXIST % name, false) if !@repo.branches.any? { |b| b.name == name }

    @repo.current_branch = @repo.branches.select { |b| b.name == name }.first
    OperationResult.new(SWITCHED_TO % name, true)
  end

  def remove(name)
    return OperationResult.new(DOES_NOT_EXIST % name, false) if !@repo.branches.any? { |b| b.name == name }

    @repo.branches.delete_if { |b| b.name == name }
    OperationResult.new(REMOVED % name, true)
  end

  def list()
    branches_list = ""
    @repo.branches.sort!
    @repo.branches.each do |b|
      prefix = (b.name == @repo.current_branch.name ? '* ' : '  ' )
      branches_list += prefix + b.name + "\n"
    end

    branches_list.chomp!
    OperationResult.new(branches_list, true)
  end
end

repo = ObjectStore.init
      repo.add('foo1', :bar1)
      first_commit = repo.commit('First commit')

      repo.add('foo2', :bar2)
      second_commit = repo.commit('Second commit')

      puts repo.log.message
# puts repo.branch.list.message
# puts repo.add('cool', 'very cool').message
# puts repo.commit('pushing cool').message
# puts repo.head.result
# puts repo.head.success?
# puts repo.head.error?
# puts repo.add('someth else', 'kool').message
# puts repo.add('meaningless', 'wut').message
# puts repo.remove('meaningless').message
# puts repo.commit('whatever').message
# puts repo.get('someth else').message
# puts repo.log
