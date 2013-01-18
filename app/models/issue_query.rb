# encoding: utf-8

require_dependency 'issue'

class IssueQuery < Query

  def initialize(attributes = nil)
    super
    self.filters ||= { :status_id => {:operator => "o", :values => [""]} }
  end

  def available_columns
    super.merge available_custom_filter_columns
  end

  def available_custom_filter_columns
    custom_fields = project ? project.all_issue_custom_fields : IssueCustomField.find(:all)
    cf_columns = custom_fields.map do |cf|
      column = {
        :sortable => (cf.order_statement || false),
        :groupable => (%w(list date bool int).include?(cf.field_format) ? cf.order_statement : false),
        :label => cf.name
      }
      ["cf_#{cf.id}".to_sym, column]
    end
    Hash[cf_columns]
  end

  # ID is always sortable.
  def sortable_columns
    [:id] + super
  end

  # Allow blank for open/closed operators.
  def blank_allowed?(name)
    super || ["o", "c"].include?(operator_for(name))
  end

  # Grab default column list from settings.
  def default_columns
    available_columns.map do |n, c|
      n if (Setting.issue_list_default_columns.include?(n.to_s) || (n == :project && project.nil?))
    end.compact
  end

  # Add available custom field filters.
  def available_filters
    super.merge available_custom_field_filters
  end

  # Overridden to add open/closed operators.
  def add_short_filter(name, expression)
    return unless expression
    parms = expression.scan(/^(o|c|!\*|!|\*)?(.*)$/).first
    add_filter name, (parms[0] || "="), [parms[1] || ""]
  end

  # Fetch the custom field for a filter from available_filters.
  def custom_for(name)
    filter_for(name)[:custom_field]
  end

  def format_for(name)
    custom = custom_for(name) || return
    custom.field_format if custom
  end

  def custom_value_for(name, item)
    custom = custom_for(name) || return
    custom_value = item.custom_values.detect { |v| v.custom_field_id == custom.id } || return
    cast_value_for(name, custom_value.value)
  end

  def cast_value_for(name, value)
    custom = custom_for(name) || (return value)
    custom.cast_value(value)
  end

  def filter_custom?(name)
    !!custom_for(name)
  end

  def sql_for(name, operator=nil, values=nil, table=nil, field=nil, type=nil)

    values ||= values_for(name).clone
    table ||= queryable_class.table_name
    operator ||= operator_for(name)
    field ||= name

    # Substitute "me" with User ID.
    if [:assigned_to_id, :author_id, :watcher_id].include?(name) || format_for(name) == 'user'
      values << (User.current.logged? ? User.current.id.to_s : "0") if values.delete("me")
    end

    case name
    when :watcher_id
      if User.current.admin?
        return "#{table}.id #{operator == '=' ? 'IN' : 'NOT IN'} (SELECT #{Watcher.table_name}.watchable_id FROM #{Watcher.table_name} WHERE #{Watcher.table_name}.watchable_type='#{queryable_class.name}' AND #{sql_for :user_id, '=', values, Watcher.table_name})"
      else
        sql_parts = []
        if User.current.logged? && user_id = values.delete(User.current.id.to_s)
          # a user can always see his own watched issues
          sql_parts << "#{table}.id #{operator == '=' ? 'IN' : 'NOT IN'} (SELECT #{Watcher.table_name}.watchable_id FROM #{Watcher.table_name} WHERE #{Watcher.table_name}.watchable_type='queryable_class.name' AND #{sql_for :user_id, '=', [user_id], Watcher.table_name})"
        end
        # filter watchers only in projects the user has the permission to view watchers in
        project_ids = User.current.projects_by_role.map { |r, p| p if r.permissions.include? :view_issue_watchers}.flatten.compact.map(&:id).uniq
        sql_parts << "#{table}.id #{operator == '=' ? 'IN' : 'NOT IN'} (SELECT #{Watcher.table_name}.watchable_id FROM #{Watcher.table_name} WHERE #{Watcher.table_name}.watchable_type='queryable_class.name' AND #{sql_for :user_id, '=', values, Watcher.table_name})"\
                     " AND #{Project.table_name}.id IN (#{project_ids.join(',')})" unless project_ids.empty?
        return "(#{sql_parts.join(' OR ')})"
      end
    when :member_of_group
      if operator == '*' # Any group
        groups = Group.all
        operator = '=' # Override the operator since we want to find by assigned_to
      elsif operator == "!*"
        groups = Group.all
        operator = '!' # Override the operator since we want to find by assigned_to
      else
        groups = Group.find_all_by_id(values)
      end
      groups ||= []

      members_of_groups = groups.inject([]) { |user_ids, group|
        if group && group.user_ids.present?
          user_ids << group.user_ids
        end
        user_ids.flatten.uniq.compact
      }.sort.map(&:to_s)

      return sql_for :assigned_to_id, operator, members_of_groups

    when :assigned_to_role
      if operator == "*" # Any Role
        roles = Role.givable
        operator = '=' # Override the operator since we want to find by assigned_to
      elsif operator == "!*" # No role
        roles = Role.givable
        operator = '!' # Override the operator since we want to find by assigned_to
      else
        roles = Role.givable.find_all_by_id(values)
      end
      roles ||= []

      members_of_roles = roles.inject([]) {|user_ids, role|
        if role && role.members
          user_ids << role.members.collect(&:user_id)
        end
        user_ids.flatten.uniq.compact
      }.sort.collect(&:to_s)

      return sql_for :assigned_to_id, operator, members_of_roles

    when :status_id
      return "#{IssueStatus.table_name}.is_closed=#{connection.quoted_false}" if operator == "o"
      return "#{IssueStatus.table_name}.is_closed=#{connection.quoted_true}" if operator == "c"

    else
      # custom field
      if filter_custom? name
        sql = sql_for :value, operator, values, CustomValue.table_name

        case operator
        when "!*"
          sql << " OR #{CustomValue.table_name}.value = ''"
        when "*"
          sql << " AND #{CustomValue.table_name}.value <> ''"
        when ">="
          sql = "CAST(#{CustomValue.table_name}.value AS decimal(60,3)) >= #{values.first.to_i}" unless [:date, :date_past].include?(type_for(name))
        when "<="
          sql = "CAST(#{CustomValue.table_name}.value AS decimal(60,3)) <= #{values.first.to_i}" unless [:date, :date_past].include?(type_for(name))
        when "<>"
          sql = "CAST(#{CustomValue.table_name}.value AS decimal(60,3)) BETWEEN #{values[0].to_i} AND #{values[1].to_i}"
        end
        return "#{table}.id IN (SELECT #{table}.id FROM #{table} LEFT OUTER JOIN #{CustomValue.table_name} ON #{CustomValue.table_name}.customized_type='#{queryable_class.name}' AND #{CustomValue.table_name}.customized_id=#{table}.id AND #{CustomValue.table_name}.custom_field_id=#{cf.id} WHERE #{sql})"
      end
    end

    super
  end

  def project_statement
    [super, Issue.visible_condition(User.current)].reject { |s| s.blank? }.join(' AND ')
  end

  def available_custom_field_filters
    if project
      custom_fields = project.all_issue_custom_fields
    else
      custom_fields = IssueCustomField.find(:all, :conditions => {:is_filter => true, :is_for_all => true})
    end

    Hash[custom_fields.select(&:is_filter?).map do |field|
      case field.field_format
      when "int", "float"
        options = { :type => :integer, :order => 20 }
      when "text"
        options = { :type => :text, :order => 20 }
      when "list"
        options = { :type => :list_optional, :choices => field.possible_values, :order => 20}
      when "date"
        options = { :type => :date, :order => 20 }
      when "bool"
        options = { :type => :list, :choices => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]], :order => 20 }
      when "user", "version"
        next unless project
        choices = field.possible_values_options(project)
        if User.current.logged? && field.field_format == 'user'
          choices.unshift ["<< #{l(:label_me)} >>", "me"]
        end
        options = { :type => :list_optional, :choices => choices, :order => 20}
      else
        options = { :type => :string, :order => 20 }
      end
      ["cf_#{field.id}".to_sym, options.merge({ :name => field.name, :custom_field => field, :label => field.name })]
    end.compact]
  end

  def count_by_group(options={})
    return super unless grouped? && filter_custom?(group_by)
    options[:include] ||= []
    counts = super
    counts.keys.inject({}) { |h, k| h[cast_value_for(group_by, k)] = counts[k]; h }
  end

  # Returns the versions
  # Valid options are :conditions
  def versions(options={})
    Version.find :all, :include => :project,
                       :conditions => self.class.merge_conditions(project_statement, options[:conditions])
  rescue ::ActiveRecord::StatementInvalid => e
    raise ActsAsQueryable::Query::StatementInvalid.new(e.message)
  end

  # Returns the journals
  # Valid options are :order, :offset, :limit
  def issue_journals(options={})
    IssueJournal.find :all, :joins => [:user, {:issue => [:project, :author, :tracker, :status]}],
                       :conditions => to_sql,
                       :order => options[:order],
                       :limit => options[:limit],
                       :offset => options[:offset]
  rescue ::ActiveRecord::StatementInvalid => e
    raise ActsAsQueryable::Query::StatementInvalid.new(e.message)
  end

end