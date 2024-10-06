# frozen_string_literal: true

require 'typesensual/rake_helper'

namespace :typesensual do
  desc 'List typesensual indices and their collections'
  task list: :environment do
    Typesensual::RakeHelper.list
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

  desc 'Index all records from a model into a new version then update the alias of the index'
  task :reindex, %i[index model] => :environment do |_, args|
    Typesensual::RakeHelper.reindex(
      index: args[:index],
      model: args[:model]
    )
  end

  desc 'Delete a version of an index'
  task :drop_version, %i[index version] => :environment do |_, args|
    Typesensual::RakeHelper.drop_version(
      index: args[:index],
      version: args[:version]
    )
  end
end
