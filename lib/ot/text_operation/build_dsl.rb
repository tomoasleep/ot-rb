# frozen_string_literal: true

module OT
  class TextOperation
    module Builder
      module_function

      # @param base [String]
      # @param from [Integer]
      # @param delete [Integer, String, nil]
      # @param insert [String, nil]
      # @return [TextOperation]
      def replace(base, from:, delete: nil, insert: nil)
        delete_length = delete.is_a?(String) ? delete.length : delete || 0
        insert_length = insert.is_a?(String) ? insert.length : insert || 0

        to = TextOperation.new

        to.retain(from) if from.positive?

        to.delete(delete_length) if delete_length.positive?

        to.insert(insert) if insert_length.positive?

        remain = base.length - from - delete_length

        to.retain(remain) if remain.positive?

        to
      end
    end
  end
end
