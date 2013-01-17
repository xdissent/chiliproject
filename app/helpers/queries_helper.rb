module QueriesHelper
  unloadable

  include QueryableHelper

  # Use Redmine::I18n
  def qt(*args)
    l(*args)
  end

  def query_scripts
    content_for :header_tags do
      super
    end
  end

  def query_styles
    content_for :header_tags do
      super
    end
  end

  def query_columns_available_label(query=nil)
    label_tag "available_columns", l(:description_available_columns), :class => "hidden-for-sighted"
  end

  def query_columns_selected_label(query=nil)
    label_tag "selected_columns", l(:description_selected_columns), :class => "hidden-for-sighted"
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
    label_tag "add_filter_select", l(:label_filter_add)
  end

  def query_group_by_label(query=nil)
    label_tag "group_by", l(:field_group_by)
  end

  def query_list_item_value(name, item, query=nil)
    query ||= @query
    if (cf = query.filter_for(name)[:custom_field])
      cv = item.custom_values.detect { |v| v.custom_field_id == cf.id }
      cv && cf.cast_value(cv.value)
    else
      super
    end
  end

  def query_apply_button(query=nil, options={})
    query ||= @query
    link_to_remote qt(:button_apply), { 
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


  # Retrieve query from session or build a new query
  # def find_query_object_with_project
  #   @query_class ||= self.class.read_inheritable_attribute('query_class')
  #   if !@query_class
  #     # Try to find the query class by checking the "model_object" class attr.
  #     model = self.class.read_inheritable_attribute('model_object')
  #     @query_class = model.queryable? && model.query_class
  #   end
  #   return unless @query_class

  #   reset = false
  #   if session[query_session_key].nil? || api_request? || session[query_session_key][:project_id] != (@project ? @project.id : nil)
  #     session[query_session_key] = nil
  #     reset = true
  #   end

  #   find_query_object_without_project
  #   return unless @query

  #   # Bail if query.project @project mismatch
  #   if @query.project && @project && @query.project.id != @project.id
  #     @query = nil
  #     return
  #   end
  #   @query.project = @project

  #   if !@query.new_record?
  #     session[query_session_key] = {:id => @query.id, :project_id => @query.project_id}
  #     sort_clear if !params[:query_id].blank?
  #   else
  #     if params[:set_filter] || reset
  #       if !(params[:fields] || params[:f]) && params[:project_id]
  #         @query.filters = @query.filters.reject { |field, v| field == "project_id" } 
  #       end
  #       @query.project
  #       @query.display_subprojects = params[:display_subprojects] if params[:display_subprojects]
  #       session[query_session_key] = {:project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names, :display_subprojects => @query.display_subprojects}
  #     end
  #   end
  # end
  # alias_method_chain :find_query_object, :project
end