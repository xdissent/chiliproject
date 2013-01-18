#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module IssueQueriesHelper
  include QueriesHelper

  # Cast custom field values.
  def query_list_item_value(name, item, query=nil)
    query ||= @query
    if filter_custom?(name)
      query.custom_value_for(name, item)
    else
      super
    end
  end

  # Issue-specific list column value transformations.
  def query_list_item_value_content(value, name, item, query=nil)
    query ||= @query
    case name
    when :subject
      link_to h(value), :controller => 'issues', :action => 'show', :id => item
    when :done_ratio
      progress_bar value, :width => '80px'
    else
      super
    end
  end
end