# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'neography/tasks'
require './neo_generate.rb'

namespace :neo4j do
  task :create do
    create_graph
  end
  task :load do
    load_graph
  end
end


SlbShare::Application.load_tasks

