# encoding: utf-8

class Query < QueryableQuery

  set_table_name "queries"

  belongs_to :project
  belongs_to :user

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

  def project_filters
    return @project_filters if @project_filters

    @project_filters = {}
    if project
      unless project.leaf?
        subprojects = project.descendants.visible.all
        unless subprojects.empty?
          # TODO: check for existence of subproject_id column
          @project_filters["subproject_id"] = { :type => :list_subprojects, :order => 13, :values => subprojects.collect{|s| [s.name, s.id.to_s] } }
        end
      end
    else
      all_projects = Project.visible.all
      project_values = []
      Project.project_tree(all_projects) do |p, level|
        prefix = (level > 0 ? ('--' * level + ' ') : '')
        project_values << ["#{prefix}#{p.name}", p.id.to_s]
      end
      @project_filters["project_id"] = { :type => :list, :order => 1, :values => project_values} unless project_values.empty?
    end
    @project_filters
  end

  def available_filters
    return @available_filters if @available_filters
    @available_filters = super.merge project_filters
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
end