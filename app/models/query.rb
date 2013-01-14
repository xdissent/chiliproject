# encoding: utf-8

class Query < QueryableQuery

  set_table_name "queries"

  belongs_to :project
  belongs_to :user

  # Translate captions
  def eval_class_columns
    self.class.available_columns.map { |c| QueryColumn.new c[:name], c.merge({:caption => l(c[:caption] || "field_#{c[:name]}")}) }
  end

  # Translate filter labels
  def label_for(field)
    label = available_filters[field][:name] if available_filters.has_key?(field)
    label ||= l("field_#{field.to_s.gsub(/\_id$/, "")}".to_sym)
  end

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

  def project_statement
    project_clauses = []
    if project && !@project.descendants.active.empty?
      ids = [project.id]
      if has_filter?("subproject_id")
        case operator_for("subproject_id")
        when '='
          # include the selected subprojects
          ids += values_for("subproject_id").each(&:to_i)
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

  def field_statement(field)
    return nil if field == "subproject_id"
    super
  end

  def statement
    [super, project_statement].reject { |s| s.blank? }.join(' AND ')
  end

  # Override day of week to start with day in settings.
  def sql_for_field(field, operator=nil, value=nil, db_table=nil, db_field=nil, is_custom_filter=false)
    if (operator || operator_for(field)) == "w"
      db_table ||= queryable_class.table_name
      db_field ||= field
      first_day_of_week = l(:general_first_day_of_week).to_i
      day_of_week = Date.today.cwday
      days_ago = (day_of_week >= first_day_of_week ? day_of_week - first_day_of_week : day_of_week + 7 - first_day_of_week)
      relative_date_clause(db_table, db_field, - days_ago, - days_ago + 6)
    else
      super
    end
  end
end