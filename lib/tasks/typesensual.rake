# frozen_string_literal: true

namespace :typesensual do
  desc 'List typesensual indices and their collections'
  task list: :environment do
    Typesensual::RakeHelper.list_collections
  end

  desc 'Update the alias for an index'
  task :update_alias, %i[index version] => :environment do |_, args|
    Typesensual::RakeHelper.update_alias(
      index: args[:index],
      version: args[:version]
    )
  end

  desc 'Index all records from a model into an index'
  task :index, %i[index model] => :environment do |_, args|
    Typesensual::RakeHelper.index(
      index: args[:index],
      model: args[:model]
    )
  end
end
