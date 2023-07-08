# frozen_string_literal: true

class Typesensual
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/typesensual.rake'
    end
  end
end
