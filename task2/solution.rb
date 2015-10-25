class RationalSequence
  include Enumerable

  def initialize(limit)
    @limit = limit
    @rising, @finished = true, true
    @num, @denom = 1, 1
  end

  def each
    current = Rational(@num, @denom)
    total = [current]

    yield current

    while total.count < @limit
      current = iteration(total)

      unless total.include? current
        yield current
        total << current
      end
    end
  end

  def iteration(total)
      if @rising and @finished
        @num += 1
        @rising = false
      elsif @finished
        @denom += 1
        @rising = true
      end

      if @finished
        @finished = false
        return Rational(@num, @denom)
      end

      @num, @denom = new_num_denom()

      @finished = true if @num == 1 or @denom == 1
      Rational(@num, @denom)
    end

  def new_num_denom()
    @rising ? [@num + 1, @denom - 1] : [@num - 1, @denom + 1]
  end
end

class Fixnum
  def prime?
    return true if self == 2
    return false if self % 2 == 0 or self < 2

    (3..self - 1).step(2) { |current| return false if self % current == 0 }
    true
  end
end

class PrimeSequence
  include Enumerable

  def initialize(limit)
    @limit = limit
  end

  def each
    current, total = 2, 0

    while total < @limit
      if current.prime?
        yield current
        total += 1
      end

      current += 1
    end
  end
end

class FibonacciSequence
  include Enumerable

  def initialize(limit, first: 1, second: 0)
    @limit = limit
    @first = first
    @second = second
  end

  def each
    current, previous = @first, @second
    total = 0

    while total < @limit
      yield current
      current, previous = current + previous, current
      total += 1
    end
  end
end

module DrunkenMathematician
  module_function

  def meaningless()
  end
end

# sequence = PrimeSequence.new(5)
# puts sequence.to_a.join(', ') # => [2, 3, 5, 7, 11]

# sequence = FibonacciSequence.new(5)
# puts sequence.to_a.join(', ') # => [1, 1, 2, 3, 5]

# sequence = FibonacciSequence.new(5, first: 0, second: 1)
# puts sequence.to_a.join(', ') # => [0, 1, 1, 2, 3]

seq = RationalSequence.new(15)
seq.each { |n| puts n }
