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

  # def column_content_with_issues(column, queryable)
  #   value = column.value(queryable)
  #   case value.class.name
  #   when 'String'
  #     if column.name == :subject
  #       link_to(h(value), :controller => 'issues', :action => 'show', :id => queryable)
  #     else
  #       column_content_without_issues(column, queryable)
  #     end
  #   when 'Fixnum', 'Float'
  #     if column.name == :done_ratio
  #       progress_bar(value, :width => '80px')
  #     else
  #       column_content_without_issues(column, queryable)
  #     end
  #   else
  #     column_content_without_issues(column, queryable)
  #   end
  # end
  # alias_method_chain :column_content, :issues
end
