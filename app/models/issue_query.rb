# encoding: utf-8

require_dependency 'issue'

class IssueQuery < Query

  def initialize(attributes = nil)
    super
    self.filters ||= { :status_id => {:operator => "o", :values => [""]} }
  end

  def available_columns
    super + (project ? project.all_issue_custom_fields : IssueCustomField.find(:all)).collect {|cf| QueryCustomFieldColumn.new(cf) }
  end

  def sortable_columns
    {'id' => "#{Issue.table_name}.id"}.merge(super)
  end

  def field_blank_allowed?(field)
    super || ["o", "c"].include?(operator_for(field))
  end

  def columns
    if has_default_columns?
      available_columns.select do |c|
        # Adds the project column by default for cross-project lists
        Setting.issue_list_default_columns.include?(c.name.to_s) || (c.name == :project && project.nil?)
      end
    else
      super
    end
  end

  def available_filters
    custom_fields_filters.merge super
  end

  def add_short_filter(field, expression)
    return unless expression
    parms = expression.scan(/^(o|c|!\*|!|\*)?(.*)$/).first
    add_filter field, (parms[0] || "="), [parms[1] || ""]
  end

  def field_statement(field)
    v = values_for(field).clone
    return nil if v.empty?
    operator = operator_for field
    sql = ''

    if %w(assigned_to_id author_id watcher_id).include?(field) ||
      # user custom fields
      available_filters.has_key?(field) && available_filters[field][:format] == 'user'
      v.push(User.current.logged? ? User.current.id.to_s : "0") if v.delete("me")
    end

    if field =~ /^cf_(\d+)$/
      # custom field
      db_table = CustomValue.table_name
      db_field = 'value'
      sql << "#{Issue.table_name}.id IN (SELECT #{Issue.table_name}.id FROM #{Issue.table_name} LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='Issue' AND #{db_table}.customized_id=#{Issue.table_name}.id AND #{db_table}.custom_field_id=#{$1} WHERE "
      sql << sql_for_field(field, operator, v, db_table, db_field, true) + ')'
    elsif field == 'watcher_id'
      db_table = Watcher.table_name
      db_field = 'user_id'
      if User.current.admin?
        # Admins can always see all watchers
        sql << "#{Issue.table_name}.id #{operator == '=' ? 'IN' : 'NOT IN'} (SELECT #{db_table}.watchable_id FROM #{db_table} WHERE #{db_table}.watchable_type='Issue' AND #{sql_for_field field, '=', v, db_table, db_field})"
      else
        sql_parts = []
        if User.current.logged? && user_id = v.delete(User.current.id.to_s)
          # a user can always see his own watched issues
          sql_parts << "#{Issue.table_name}.id #{operator == '=' ? 'IN' : 'NOT IN'} (SELECT #{db_table}.watchable_id FROM #{db_table} WHERE #{db_table}.watchable_type='Issue' AND #{sql_for_field field, '=', [user_id], db_table, db_field})"
        end
        # filter watchers only in projects the user has the permission to view watchers in
        project_ids = User.current.projects_by_role.collect {|r,p| p if r.permissions.include? :view_issue_watchers}.flatten.compact.collect(&:id).uniq
        sql_parts << "#{Issue.table_name}.id #{operator == '=' ? 'IN' : 'NOT IN'} (SELECT #{db_table}.watchable_id FROM #{db_table} WHERE #{db_table}.watchable_type='Issue' AND #{sql_for_field field, '=', v, db_table, db_field})"\
                     " AND #{Project.table_name}.id IN (#{project_ids.join(',')})" unless project_ids.empty?
        sql << "(#{sql_parts.join(' OR ')})"
      end
    elsif field == "member_of_group" # named field
      if operator == '*' # Any group
        groups = Group.all
        operator = '=' # Override the operator since we want to find by assigned_to
      elsif operator == "!*"
        groups = Group.all
        operator = '!' # Override the operator since we want to find by assigned_to
      else
        groups = Group.find_all_by_id(v)
      end
      groups ||= []

      members_of_groups = groups.inject([]) {|user_ids, group|
        if group && group.user_ids.present?
          user_ids << group.user_ids
        end
        user_ids.flatten.uniq.compact
      }.sort.collect(&:to_s)

      sql << '(' + sql_for_field("assigned_to_id", operator, members_of_groups, Issue.table_name, "assigned_to_id", false) + ')'

    elsif field == "assigned_to_role" # named field
      if operator == "*" # Any Role
        roles = Role.givable
        operator = '=' # Override the operator since we want to find by assigned_to
      elsif operator == "!*" # No role
        roles = Role.givable
        operator = '!' # Override the operator since we want to find by assigned_to
      else
        roles = Role.givable.find_all_by_id(v)
      end
      roles ||= []

      members_of_roles = roles.inject([]) {|user_ids, role|
        if role && role.members
          user_ids << role.members.collect(&:user_id)
        end
        user_ids.flatten.uniq.compact
      }.sort.collect(&:to_s)

      sql << '(' + sql_for_field("assigned_to_id", operator, members_of_roles, Issue.table_name, "assigned_to_id", false) + ')'
    else
      sql << super
    end

    sql
  end

  # Helper method to generate the WHERE sql for a +field+, +operator+ and a +value+
  def sql_for_field(field, operator=nil, value=nil, db_table=nil, db_field=nil, is_custom_filter=false)
    case (operator || operator_for(field))
    when "o"
      return "#{IssueStatus.table_name}.is_closed=#{connection.quoted_false}" if field == "status_id"
    when "c"
      return "#{IssueStatus.table_name}.is_closed=#{connection.quoted_true}" if field == "status_id"
    end
    super
  end

  def project_statement
    [super, Issue.visible_condition(User.current)].reject { |s| s.blank? }.join(' AND ')
  end

  def custom_fields_filters
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
        options = { :type => :list_optional, :values => field.possible_values, :order => 20}
      when "date"
        options = { :type => :date, :order => 20 }
      when "bool"
        options = { :type => :list, :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]], :order => 20 }
      when "user", "version"
        next unless project
        values = field.possible_values_options(project)
        if User.current.logged? && field.field_format == 'user'
          values.unshift ["<< #{l(:label_me)} >>", "me"]
        end
        options = { :type => :list_optional, :values => values, :order => 20}
      else
        options = { :type => :string, :order => 20 }
      end
      ["cf_#{field.id}", options.merge({ :name => field.name, :format => field.field_format })]
    end.compact]
  end

  # Returns the issue count
  def issue_count
    Issue.count(:include => [:status, :project], :conditions => statement)
  rescue ::ActiveRecord::StatementInvalid => e
    raise Query::StatementInvalid.new(e.message)
  end

  # Returns the issue count by group or nil if query is not grouped
  def issue_count_by_group
    r = nil
    if grouped?
      begin
        # Rails will raise an (unexpected) RecordNotFound if there's only a nil group value
        r = Issue.count(:group => group_by_statement, :include => [:status, :project], :conditions => statement)
      rescue ActiveRecord::RecordNotFound
        r = {nil => issue_count}
      end
      c = group_by_column
      if c.is_a?(QueryCustomFieldColumn)
        r = r.keys.inject({}) {|h, k| h[c.custom_field.cast_value(k)] = r[k]; h}
      end
    end
    r
  rescue ::ActiveRecord::StatementInvalid => e
    raise Query::StatementInvalid.new(e.message)
  end

  # Returns the issues
  # Valid options are :order, :offset, :limit, :include, :conditions
  def issues(options={})
    order_option = [group_by_sort_order, options[:order]].reject {|s| s.blank?}.join(',')
    order_option = nil if order_option.blank?

    Issue.find :all, :include => ([:status, :project] + (options[:include] || [])).uniq,
                     :conditions => self.class.merge_conditions(statement, options[:conditions]),
                     :order => order_option,
                     :limit  => options[:limit],
                     :offset => options[:offset]
  rescue ::ActiveRecord::StatementInvalid => e
    raise Query::StatementInvalid.new(e.message)
  end

  # Returns the journals
  # Valid options are :order, :offset, :limit
  def issue_journals(options={})
    IssueJournal.find :all, :joins => [:user, {:issue => [:project, :author, :tracker, :status]}],
                       :conditions => statement,
                       :order => options[:order],
                       :limit => options[:limit],
                       :offset => options[:offset]
  rescue ::ActiveRecord::StatementInvalid => e
    raise Query::StatementInvalid.new(e.message)
  end

  # Returns the versions
  # Valid options are :conditions
  def versions(options={})
    Version.find :all, :include => :project,
                       :conditions => self.class.merge_conditions(project_statement, options[:conditions])
  rescue ::ActiveRecord::StatementInvalid => e
    raise Query::StatementInvalid.new(e.message)
  end
end