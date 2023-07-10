# frozen_string_literal: true

RSpec::Matchers.define :be_operation do
  match do |actual|
    @applied = actual.apply(@from)
    @applied == @to
  end

  chain :from do |from|
    @from = from
  end

  chain :to do |to|
    @to = to
  end

  failure_message do |actual|
    "Expected to be an operation which changes #{@from} to #{@to}, but (#{actual}) changes to #{@applied}"
  end

  description do
    "be an operation which changes #{@from} to #{@to}"
  end
end
