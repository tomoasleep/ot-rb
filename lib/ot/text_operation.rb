# frozen_string_literal: true

# This is a port of ot.js to Ruby.
# https://github.com/Operational-Transformation/ot.js/blob/v0.0.15/lib/text-operation.js

# Copyright (c) 2012-2014 Tim Baumann, http://timbaumann.info
# Released under the MIT license
# https://opensource.org/licenses/mit-license.php

module OT
  class TextOperation
    # @return [Array<String, Integer>]
    attr_reader :ops

    # @return [Integer]
    attr_reader :base_length

    # @return [Integer]
    attr_reader :target_length

    def initialize
      @ops = []
      @base_length = 0
      @target_length = 0
    end

    class << self
      # @param op [Integer, String]
      def retain?(op)
        op.is_a?(Integer) && op > 0
      end

      # @param op [Integer, String]
      def insert?(op)
        op.is_a?(String)
      end

      # @param op [Integer, String]
      def delete?(op)
        op.is_a?(Integer) && op < 0
      end
    end

    # @param n [Integer]
    # @return [TextOperation]
    def retain(n)
      raise ArgumentError, "retain expects an integer" unless n.is_a?(Integer)
      return self if n == 0

      @base_length += n
      @target_length += n

      if self.class.retain?(ops.last)
        ops[-1] += n
      else
        ops.push(n)
      end

      self
    end

    # @param str [String]
    # @return [TextOperation]
    def insert(str)
      raise ArgumentError, "insert expects a string" unless str.is_a?(String)
      return self if str.empty?

      @target_length += str.length

      if self.class.insert?(ops[-1])
        ops[-1] += str
      elsif self.class.delete?(ops[-1])
        # It doesn't matter when an operation is applied whether the operation
        # is delete(3), insert("something") or insert("something"), delete(3).
        # Here we enforce that in this case, the insert op always comes first.
        # This makes all operations that have the same effect when applied to
        # a document of the right length equal in respect to the `equals` method.
        if self.class.insert?(ops[-2])
          ops[-2] += str
        else
          ops.push(ops[-1])
          ops[-2] = str
        end
      else
        ops.push(str)
      end

      self
    end

    # @param n [Integer, String]
    # @return [TextOperation]
    def delete(n)
      n = n.length if n.is_a?(String)
      raise ArgumentError, "delete expects an integer or a string" unless n.is_a?(Integer)
      return self if n == 0

      n = -n if n > 0
      @base_length -= n

      if self.class.delete?(ops[-1])
        ops[-1] += n
      else
        ops.push(n)
      end

      self
    end

    def noop?
      ops.empty? || (ops.length == 1 && self.class.retain?(ops[0]))
    end

    # @return [String]
    def to_s
      ops.map do |op|
        if self.class.retain?(op)
          "retain #{op}"
        elsif self.class.insert?(op)
          "insert '#{op}'"
        else
          "delete #{-op}"
        end
      end.join(", ")
    end

    # Apply an operation to a string, returning a new string. Throws an error if
    # there's a mismatch between the input string and the operation.
    #
    # @param text [String]
    # @return [String]
    def apply(text)
      if text.length != base_length
        raise ArgumentError, "The operation's base length must be equal to the string's length."
      end

      new_text = []
      pos = 0

      ops.each do |op|
        if self.class.retain?(op)
          new_text.push(text[pos...(pos + op)])
          pos += op
        elsif self.class.insert?(op)
          new_text.push(op)
        else
          pos -= op
        end
      end

      raise ArgumentError, "The operation didn't operate on the whole string." if pos != text.length

      new_text.join
    end

    # Compose merges two consecutive operations into one operation, that
    # preserves the changes of both. Or, in other words, for each input string S
    # and a pair of consecutive operations A and B,
    # apply(apply(S, A), B) = apply(S, compose(A, B)) must hold.
    #
    # @param operation2 [TextOperation]
    # @return [TextOperation]
    def compose(operation2)
      operation1 = self
      raise ArgumentError, "The base length of the second operation has to be the target length of the first operation" if operation1.target_length != operation2.base_length

      operation = TextOperation.new

      ops1 = TextOperation::Iterator.new(operation1)
      ops2 = TextOperation::Iterator.new(operation2)

      op1 = ops1.next
      op2 = ops2.next

      loop do
        # Dispatch on the type of op1 and op2
        if op1.nil? && op2.nil?
          # end condition: both ops1 and ops2 have been processed
          break
        end

        if self.class.delete?(op1)
          operation.delete(op1)
          op1 = ops1.next
          next
        end
        if self.class.insert?(op2)
          operation.insert(op2)
          op2 = ops2.next
          next
        end

        raise "Cannot compose operations: first operation is too short." if op1.nil?
        raise "Cannot compose operations: first operation is too long." if op2.nil?

        if self.class.retain?(op1) && self.class.retain?(op2)
          if op1 > op2
            operation.retain(op2)
            op1 = op1 - op2
            op2 = ops2.next
          elsif op1 == op2
            operation.retain(op1)
            op1 = ops1.next
            op2 = ops2.next
          else
            operation.retain(op1)
            op2 = op2 - op1
            op1 = ops1.next
          end
        elsif self.class.insert?(op1) && self.class.delete?(op2)
          if op1.length > -op2
            op1 = op1.slice(-op2..)
            op2 = ops2.next
          elsif op1.length == -op2
            op1 = ops1.next
            op2 = ops2.next
          else
            op2 = op2 + op1.length
            op1 = ops1.next
          end
        elsif self.class.insert?(op1) && self.class.retain?(op2)
          if op1.length > op2
            operation.insert(op1.slice(0..(op2 - 1)))
            op1 = op1.slice(op2..)
            op2 = ops2.next
          elsif op1.length == op2
            operation.insert(op1)
            op1 = ops1.next
            op2 = ops2.next
          else
            operation.insert(op1)
            op2 = op2 - op1.length
            op1 = ops1.next
          end
        elsif self.class.retain?(op1) && self.class.delete?(op2)
          if op1 > -op2
            operation.delete(op2)
            op1 = op1 + op2
            op2 = ops2.next
          elsif op1 == -op2
            operation.delete(op2)
            op1 = ops1.next
            op2 = ops2.next
          else
            operation.delete(op1)
            op2 = op2 + op1
            op1 = ops1.next
          end
        else
          raise "This shouldn't happen: op1: #{op1.inspect}, op2: #{op2.inspect}"
        end
      end

      operation
    end

    # Transform takes two operations A and B that happened concurrently and
    # produces two operations A' and B' (in an array) such that
    # `apply(apply(S, A), B') = apply(apply(S, B), A')`. This function is the
    # heart of OT.
    #
    # @param operation1 [TextOperation]
    # @param operation2 [TextOperation]
    # @return [(TextOperation, TextOperation))]
    def self.transform(operation1, operation2)
      raise ArgumentError, "Both operations have to have the same base length." if operation1.base_length != operation2.base_length

      operation1_prime = TextOperation.new
      operation2_prime = TextOperation.new

      ops1 = TextOperation::Iterator.new(operation1)
      ops2 = TextOperation::Iterator.new(operation2)

      op1 = ops1.next
      op2 = ops2.next

      loop do
        # At every iteration of the loop, the imaginary cursor that both
        # operation1 and operation2 have that operates on the input string must
        # have the same position in the input string.

        if op1.nil? && op2.nil?
          # end condition: both ops1 and ops2 have been processed
          break
        end

        # next two cases: one or both ops are insert ops
        # => insert the string in the corresponding prime operation, skip it in
        # the other one. If both op1 and op2 are insert ops, prefer op1.
        if insert?(op1)
          operation1_prime.insert(op1)
          operation2_prime.retain(op1.length)

          op1 = ops1.next
          next
        end
        if insert?(op2)
          operation1_prime.retain(op2.length)
          operation2_prime.insert(op2)

          op2 = ops2.next
          next
        end

        raise "Cannot compose operations: first operation is too short." if op1.nil?
        raise "Cannot compose operations: first operation is too long." if op2.nil?

        minl = nil
        if retain?(op1) && retain?(op2)
          # Simple case: retain/retain
          if op1 > op2
            minl = op2
            op1 = op1 - op2
            op2 = ops2.next
          elsif op1 == op2
            minl = op2
            op1 = ops1.next
            op2 = ops2.next
          else
            minl = op1
            op2 = op2 - op1
            op1 = ops1.next
          end
          operation1_prime.retain(minl)
          operation2_prime.retain(minl)
        elsif delete?(op1) && delete?(op2)
          # Both operations delete the same string at the same position. We don't
          # need to produce any operations, we just skip over the delete ops and
          # handle the case that one operation deletes more than the other.
          if -op1 > -op2
            op1 = op1 - op2
            op2 = ops2.next
          elsif op1 == op2
            op1 = ops1.next
            op2 = ops2.next
          else
            op2 = op2 - op1
            op1 = ops1.next
          end
          # next two cases: delete/retain and retain/delete
        elsif delete?(op1) && retain?(op2)
          if -op1 > op2
            minl = op2
            op1 = op1 + op2
            op2 = ops2.next
          elsif -op1 == op2
            minl = op2
            op1 = ops1.next
            op2 = ops2.next
          else
            minl = -op1
            op2 = op2 + op1
            op1 = ops1.next
          end
          operation1_prime.delete(minl)
        elsif retain?(op1) && delete?(op2)
          if op1 > -op2
            minl = -op2
            op1 = op1 + op2
            op2 = ops2.next
          elsif op1 == -op2
            minl = op1
            op1 = ops1.next
            op2 = ops2.next
          else
            minl = op1
            op2 = op2 + op1
            op1 = ops1.next
          end
          operation2_prime.delete(minl)
        else
          raise "The two operations aren't compatible"
        end
      end

      [operation1_prime, operation2_prime]
    end
  end
end

require_relative "text_operation/build_dsl"
require_relative "text_operation/iterator"
