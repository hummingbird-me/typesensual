# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'

  track_files '{exe,lib}/**/*.rb'
end
