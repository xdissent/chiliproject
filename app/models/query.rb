# encoding: utf-8

class Query < QueryableQuery

  set_table_name "queries"

  belongs_to :project
  belongs_to :user

  # Override operators for translation
  self.operators = {
    "="   => :label_equals,
    "!"   => :label_not_equals,
    "!*"  => :label_none,
    "*"   => :label_all,
    ">="  => :label_greater_or_equal,
    "<="  => :label_less_or_equal,
    "><"  => :label_between,
    "<t+" => :label_in_less_than,
    ">t+" => :label_in_more_than,
    "t+"  => :label_in,
    "t"   => :label_today,
    "w"   => :label_this_week,
    ">t-" => :label_less_than_ago,
    "<t-" => :label_more_than_ago,
    "t-"  => :label_ago,
    "~"   => :label_contains,
    "!~"  => :label_not_contains
  }

  def initialize(attributes = nil)
    super attributes
    self.display_subprojects ||= Setting.display_subprojects_issues?
  end

  def editable_by?(user)
    return false unless user
    # Admin can edit them all and regular users can edit their private queries
    return true if user.admin? || (!is_public && self.user_id == user.id)
    # Members can not edit public queries that are for all project (only admin is allowed to)
    is_public && project && user.allowed_to?(:manage_public_queries, project)
  end

  def user_values
    return @user_values if @user_values
    @user_values = []
    @user_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    if project
      @user_values += project.users.sort.collect{|s| [s.name, s.id.to_s] }
    else
      all_projects = Project.visible.all
      if all_projects.any?
        # members of visible projects
        @user_values += User.active.find(:all, :conditions => ["#{User.table_name}.id IN (SELECT DISTINCT user_id FROM members WHERE project_id IN (?))", all_projects.collect(&:id)]).sort.collect{|s| [s.name, s.id.to_s] }
      end
    end
    @user_values
  end

  def to_sql
    [super, project_statement].reject { |s| s.blank? }.join(' AND ')
  end

  def label_for(name, options={})
    l(name, {:default => name.to_s.titleize}.merge(options))
  end

  def column_label_for(name)
    column_for(name)[:label] || l("field_#{name}".to_sym, :default => label_for(name))
  end

  def filter_label_for(name)
    filter_for(name)[:label] || l("field_#{name}".gsub(/_id$/, '').to_sym, :default => label_for(name))
  end

private

  def sql_for(name, operator=nil, values=nil, table=nil, field=nil, type=nil)
    return nil if name == :subproject_id
    return super unless operator_for(name) == "w"
    # Override day of week to start with day in settings.
    first_day_of_week = l(:general_first_day_of_week).to_i
    day_of_week = Date.today.cwday
    days_ago = (day_of_week >= first_day_of_week ? day_of_week - first_day_of_week : day_of_week + 7 - first_day_of_week)
    relative_date_clause((table || queryable_class.table_name), (field || name), - days_ago, - days_ago + 6)
  end

  def project_statement
    project_clauses = []
    if project && !@project.descendants.active.empty?
      ids = [project.id]
      if has_filter?(:subproject_id)
        case operator_for(:subproject_id)
        when '='
          # include the selected subprojects
          ids += values_for(:subproject_id).each(&:to_i)
        when '!*'
          # main project only
        else
          # all subprojects
          ids += project.descendants.collect(&:id)
        end
      elsif display_subprojects?
        ids += project.descendants.collect(&:id)
      end
      project_clauses << "#{Project.table_name}.id IN (%s)" % ids.join(',')
    elsif project
      project_clauses << "#{Project.table_name}.id = %d" % project.id
    end
    project_clauses.join(' AND ')
  end
end