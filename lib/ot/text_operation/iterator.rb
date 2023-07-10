# frozen_string_literal: true

module OT
  class TextOperation
    # Simplify iteration of ops in QiitaTeam::OT::TextOperation.
    #
    # This class is not a part of original ot.js but is used to port ot.js to Ruby.
    class Iterator
      # @return [QiitaTeam::OT::TextOperation]
      attr_reader :text_operation

      # @param [QiitaTeam::OT::TextOperation] text_operation
      def initialize(text_operation)
        @text_operation = text_operation
      end

      # @return [String, Integer, nil]
      def next
        enumerator.next
      rescue StopIteration
        nil
      end

      private

      # @return [Enumerator<String, Integer>]
      def enumerator
        @enumerator ||= text_operation.ops.to_enum
      end
    end
  end
end
