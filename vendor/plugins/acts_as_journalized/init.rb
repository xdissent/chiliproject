#-- encoding: UTF-8
$LOAD_PATH.unshift File.expand_path("../lib/", __FILE__)

require "acts_as_journalized"
ActiveRecord::Base.send(:include, Redmine::Acts::Journalized)

ChiliProject::Application.config.to_prepare do
  # Model
  require_dependency "journal"
end
