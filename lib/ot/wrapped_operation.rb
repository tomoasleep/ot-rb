# frozen_string_literal: true

# This is a port of ot.js to Ruby.
# https://github.com/Operational-Transformation/ot.js/blob/v0.0.15/lib/wrapped-operation.js

# Copyright (c) 2012-2014 Tim Baumann, http://timbaumann.info
# Released under the MIT license
# https://opensource.org/licenses/mit-license.php

module OT
  class WrappedOperation
    # @return [TextOperation, WrappedOperation]
    attr_reader :wrapped

    # @return [Object]
    attr_reader :meta

    # @param operation [TextOperation, WrappedOperation]
    # @param meta [Object]
    def initialize(operation, meta)
      @wrapped = operation
      @meta = meta
    end

    def apply(...)
      wrapped.apply(...)
    end

    # @param other [WrappedOperation]
    def compose(other)
      WrappedOperation.new(
        wrapped.compose(other.wrapped),
        self.class.compose_meta(meta, other.meta),
      )
    end

    class << self
      # @param wop1 [WrappedOperation]
      # @param wop2 [WrappedOperation]
      # @return [(WrappedOperation, WrappedOperation)]
      def transform(wop1, wop2)
        op1_t, op2_t = wop1.wrapped.class.transform(wop1.wrapped, wop2.wrapped)

        [
          WrappedOperation.new(op1_t, transform_meta(wop1.meta, wop2)),
          WrappedOperation.new(op2_t, transform_meta(wop2.meta, wop1)),
        ]
      end

      # @param meta [Object]
      # @param operation [WrappedOperation]
      # @return [Object]
      def transform_meta(meta, wop)
        if meta.respond_to?(:transform)
          meta.transform(wop)
        else
          meta
        end
      end

      # @param meta1 [#compose, #merge, Object]
      # @param meta2 [#compose, #merge, Object]
      def compose_meta(meta1, meta2)
        if meta1.respond_to?(:compose)
          meta1.compose(meta2)
        elsif meta1.respond_to?(:merge)
          meta1.merge(meta2)
        else
          meta2
        end
      end
    end
  end
end
