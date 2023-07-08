# frozen_string_literal: true

class Typesensual
  module StateHelpers
    extend ActiveSupport::Concern

    delegate :config, :env, :client, to: :class

    class_methods do
      delegate :config, to: :Typesensual
      delegate :env, :client, to: :config, allow_nil: true
    end
  end
end
