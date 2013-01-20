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

module QueriesHelper

  include QueryableHelper

  # Use Redmine::I18n
  def qt(*args)
    l(*args)
  end

  def query_scripts
    content_for :header_tags do
      super
    end
    nil
  end

  def query_styles
    content_for :header_tags do
      super
    end
    nil
  end

  def query_list_headers(query=nil)
    query ||= @query
    query.columns.map do |name|
      if (s = query.sortable_for(name))
        sort_header_tag name.to_s, 
          :caption => query.column_label_for(name),
          :default_order => query.default_order_for(name) 
      else
        content_tag :th, query.column_label_for(name)
      end
    end.join("")
  end

  def query_columns_available_label(query=nil)
    label_tag "available_columns", l(:description_available_columns)
  end

  def query_columns_selected_label(query=nil)
    label_tag "selected_columns", l(:description_selected_columns)
  end

  def query_filter_operator_label(field, query=nil)
    label_tag "operators_#{field}", l(:description_filter), :class => "hidden-for-sighted"
  end

  def query_sort_criteria_attribute_label(index=0, query=nil)
    label_tag "query_sort_criteria_attribute_#{index}", l(:description_query_sort_criteria_attribute), :class => "hidden-for-sighted"
  end

  def query_sort_criteria_direction_label(index=0, query=nil)
    label_tag "query_sort_criteria_direction_#{index}", l(:description_query_sort_criteria_direction), :class => "hidden-for-sighted"
  end

  def query_sort_criteria_direction_options(query=nil)
    [["", ""], [l(:label_ascending), "asc"], [l(:label_descending), "desc"]]
  end

  def query_filter_add_options(query=nil)
    [["", ""]] + super[1..-1]
  end

  def query_filter_add_label(query=nil)
    label_tag("add_filter_select", (l(:label_filter_add) + ":"))
  end

  def query_group_by_label(query=nil)
    label_tag "group_by", l(:field_group_by)
  end

  def query_columns_available_buttons
    (content_tag(:button, "&#8594;", :type => :button, :onclick => "moveOptions(this.form.available_columns, this.form.selected_columns); return false;") + "<br>" +
      content_tag(:button, "&#8592;", :onclick => "moveOptions(this.form.selected_columns, this.form.available_columns); return false;"))
  end

  def query_columns_selected_buttons
    (content_tag(:button, "&#8593;", :onclick => "moveOptionUp(this.form.selected_columns); return false;") + "<br>" +
      content_tag(:button, "&#8595;", :onclick => "moveOptionDown(this.form.selected_columns); return false;"))
  end

  def query_apply_button(query=nil, options={})
    query ||= @query
    link_to_remote l(:button_apply), { 
      :url => { :set_filter => 1 },
      :before => "selectAllOptions('selected_columns');",
      :update => "content",
      :complete => "apply_filters_observer()",
      :with => "Form.serialize('query_form')"
    }.merge(options)
  end

  def query_list_item_value_content(value, name, item, query=nil)
    query ||= @query
    case value.class.name
    when 'User'
      link_to_user value
    when 'Project'
      link_to_project value
    when 'Version'
      link_to(h(value), :controller => 'versions', :action => 'show', :id => value)
    when 'Issue'
      link_to_issue(value, :subject => false)
    when 'TrueClass'
      l(:general_text_Yes)
    when 'FalseClass'
      l(:general_text_No)
    else
      super
    end
  end

  def find_query_by_id_conditions
    cond = "project_id IS NULL"
    cond << " OR project_id = #{@project.id}" if @project
  end

  def find_query_new(attrs={})
    super(attrs.merge :project => @project)
  end

  def find_query_by_id
    super
    return unless @query
    @query.project = @project
    session[query_session_key][:project_id] = @query.project_id
    sort_clear
  end

  def find_query_by_session
    return find_query_by_params if api_request? || session[query_session_key][:project_id] != (@project ? @project.id : nil)
    super
  end

  def find_query_by_params
    super
    return unless @query
    @query.display_subprojects = params[:display_subprojects] if params[:display_subprojects]
    session[query_session_key][:project_id] = @query.project_id
    session[query_session_key][:display_subprojects] = @query.display_subprojects
  end

  def find_query
    super
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Rescues an invalid query statement. Just in case...
  def query_statement_invalid(exception)
    logger.error "ActsAsQueryable::Query::StatementInvalid: #{exception.message}" if logger
    session.delete(query_session_key)
    sort_clear if respond_to?(:sort_clear)
    render_error "An error occurred while executing the query and has been logged. Please report this error to your administrator."
  end
end