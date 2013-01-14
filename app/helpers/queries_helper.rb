module QueriesHelper
  include QueryableHelper

  def query_filter_operators_for_with_label(field, query=nil)
    query ||= @query
    (label_tag("operators_#{field}", l(:description_filter), :class => "hidden-for-sighted") + 
      query_filter_operators_for_without_label(field, query))
  end
  alias_method_chain :query_filter_operators_for, :label

  def operators_for_select_with_i18n(filter_type, query_class=nil)
    operators_for_select_without_i18n(filter_type, query_class).map { |o| [l(o[0]), o[1]] }
  end
  alias_method_chain :operators_for_select, :i18n

  def query_filter_add_with_i18n(query=nil)
    query ||= @query
    field_options = query.available_filters_sorted.map do |field| 
      [query.label_for(field[0]), field[0]] unless query.has_filter?(field[0])
    end.compact
    (label_tag('add_filter_select', l(:label_filter_add)) + 
      select_tag('add_filter_select', 
        options_for_select([["",""]] + field_options),
        :onchange => "add_filter();",
        :class => "select-small",
        :name => nil))
  end
  alias_method_chain :query_filter_add, :i18n

  def query_filter_scripts_with_head(query=nil)
    query ||= @query
    return if @query_scripted
    @query_scripted = true
    content_for :header_tags do
      concat query_filter_scripts_without_head(query)
    end
  end
  alias_method_chain :query_filter_scripts, :head

  def column_content_with_chiliproject(column, queryable)
    value = column.value(queryable)
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
      column_content_without_chiliproject(column, queryable)
    end
  end
  alias_method_chain :column_content, :chiliproject

  # Retrieve query from session or build a new query
  def find_query_object_with_project
    @query_class ||= self.class.read_inheritable_attribute('query_class')
    if !@query_class
      # Try to find the query class by checking the "model_object" class attr.
      model = self.class.read_inheritable_attribute('model_object')
      @query_class = model.queryable? && model.query_class
    end
    return unless @query_class

    reset = false
    if session[query_session_key].nil? || api_request? || session[query_session_key][:project_id] != (@project ? @project.id : nil)
      session[query_session_key] = nil
      reset = true
    end

    find_query_object_without_project
    return unless @query

    # Bail if query.project @project mismatch
    if @query.project && @project && @query.project.id != @project.id
      @query = nil
      return
    end
    @query.project = @project

    if !@query.new_record?
      session[query_session_key] = {:id => @query.id, :project_id => @query.project_id}
      sort_clear if !params[:query_id].blank?
    else
      if params[:set_filter] || reset
        if !(params[:fields] || params[:f]) && params[:project_id]
          @query.filters = @query.filters.reject { |field, v| field == "project_id" } 
        end
        @query.project
        @query.display_subprojects = params[:display_subprojects] if params[:display_subprojects]
        session[query_session_key] = {:project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names, :display_subprojects => @query.display_subprojects}
      end
    end
  end
  alias_method_chain :find_query_object, :project
end