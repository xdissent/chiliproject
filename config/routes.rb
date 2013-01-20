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

ChiliProject::Application.routes.draw do
  root :to => 'welcome#index', :as => 'home'

  match 'login' => 'account#login', :as => 'signin'
  match 'logout' => 'account#logout', :as => 'signout'
  match 'account/lost_password', :to => 'account#lost_password', :via => [:get, :post]
  match 'account/register' => 'account#register'

  match 'my/account', :controller => 'my', :action => 'account', :via => [:get, :post]
  match 'my/account/destroy', :controller => 'my', :action => 'destroy', :via => [:get, :post]
  match 'my/page', :controller => 'my', :action => 'page', :via => :get
  match 'my', :controller => 'my', :action => 'index', :via => :get
  match 'my/reset_rss_key', :controller => 'my', :action => 'reset_rss_key', :via => :post
  match 'my/reset_api_key', :controller => 'my', :action => 'reset_api_key', :via => :post
  match 'my/password', :controller => 'my', :action => 'password', :via => [:get, :post]
  match 'my/page_layout', :controller => 'my', :action => 'page_layout', :via => :get
  match 'my/add_block', :controller => 'my', :action => 'add_block', :via => :post
  match 'my/remove_block', :controller => 'my', :action => 'remove_block', :via => :post
  match 'my/order_blocks', :controller => 'my', :action => 'order_blocks', :via => :post

  match 'search/index' => 'search#index'



  #TODO clear it
  match 'ldap_auth_sources' => 'ldap_auth_sources#index'

  match 'roles/workflow/:id/:role_id/:tracker_id' => 'roles#workflow'
  match 'help/:ctrl/:page' => 'help#index'

  scope :controller => 'time_entry_reports', :action => 'report', :via => :get do
    match 'projects/:project_id/issues/:issue_id/time_entries/report(.:format)'
    match 'projects/:project_id/time_entries/report(.:format)'
    match 'time_entries/report(.:format)'
  end

  resources :time_entries, :controller => 'timelog'

  match 'projects/:id/wiki' => 'wikis#edit', :via => :post
  match 'projects/:id/wiki/destroy' => 'wikis#destroy', :via => [:get, :post]

  scope :controller => 'messages' do
    scope :via => :get do
      match 'boards/:board_id/topics/new', :action => :new
      match 'boards/:board_id/topics/:id', :action => :show
      match 'boards/:board_id/topics/:id/edit', :action => :edit
    end
    scope :via => :post do
      match 'boards/:board_id/topics/new', :action => :new
      match 'boards/:board_id/topics/:id/replies', :action => :reply
      match 'boards/:board_id/topics/:id/:action', :action => /edit|destroy/
    end
  end

  scope :controller => 'boards' do
    scope :via => :get do
      match 'projects/:project_id/boards', :action => :index
      match 'projects/:project_id/boards/new', :action => :new
      match 'projects/:project_id/boards/:id(.:format)', :action => :show
      match 'projects/:project_id/boards/:id/:edit', :action => :edit
    end
    scope :via => :post do
      match 'projects/:project_id/boards', :action => :new
      match 'projects/:project_id/boards/:id/:action', :action => /edit|destroy/
    end
  end

  scope :controller => 'documents' do
    scope :via => :get do
      match 'projects/:project_id/documents', :action => :index
      match 'projects/:project_id/documents/new', :action => :new
      match 'documents/:id', :action => :show
      match 'documents/:id/:edit', :action => :edit
    end
    scope :via => :post do
      match 'projects/:project_id/documents', :action => :new
      match 'documents/:id/:action', :action => /edit|destroy/
    end
  end

  scope 'issues' do
    resources :issue_moves, :only => [:new, :create], :as => 'move'
  end

  # Misc issue routes. TODO: move into resources
  match 'issues/auto_complete' => 'auto_completes#issues', :as => 'auto_complete_issues'
  match 'issues/preview/:id' => 'previews#issue', :as => 'preview_issue' # TODO: would look nicer as /issues/:id/preview
  match 'issues/context_menu' => 'context_menus#issues', :as => 'issues_context_menu'
  match 'issues/changes' => 'journals#index', :as => 'issue_changes'
  match 'issues/bulk_edit' => 'issues#bulk_edit', :via => :get, :as => 'bulk_edit_issue'
  match 'issues/bulk_edit' => 'issues#bulk_update', :via => :post, :as => 'bulk_update_issue'
  match 'issues/:id/quoted' => 'journals#new', :id => /\d+/, :via => :post, :as => 'quoted_issue'
  match 'issues/:id/destroy' => 'issues#destroy', :via => :post # legacy


  match 'admin', :controller => 'admin', :action => 'index', :via => :get
  match 'admin/projects', :controller => 'admin', :action => 'projects', :via => :get
  match 'admin/plugins', :controller => 'admin', :action => 'plugins', :via => :get
  match 'admin/info', :controller => 'admin', :action => 'info', :via => :get
  match 'admin/test_email', :controller => 'admin', :action => 'test_email', :via => :get
  match 'admin/default_configuration', :controller => 'admin', :action => 'default_configuration', :via => :post

  match 'workflows', :controller => 'workflows', :action => 'index', :via => :get
  match 'workflows/edit', :controller => 'workflows', :action => 'edit', :via => [:get, :post]
  match 'workflows/copy', :controller => 'workflows', :action => 'copy', :via => [:get, :post]
  match 'settings', :controller => 'settings', :action => 'index', :via => :get
  match 'settings/edit', :controller => 'settings', :action => 'edit', :via => [:get, :post]
  match 'settings/plugin/:id', :controller => 'settings', :action => 'plugin', :via => [:get, :post]

  resources :custom_fields, :except => :show


  scope 'issues' do
    resource :gantt, :only => [:show, :update]
    resource :calendar, :only => [:show, :update]
  end
  scope 'projects/:project_id/issues' do
    resource :gantt, :only => [:show, :update]
    resource :calendar, :only => [:show, :update]
  end

  scope :controller => 'reports', :via => :get do
    match 'projects/:id/issues/report', :action => 'issue_report'
    match 'projects/:id/issues/report/:detail', :action => 'issue_report_details'
  end

  # Following two routes conflict with the resources because #index allows POST
  match 'issues' => 'issues#index', :via => :post
  match 'issues/create' => 'issues#index', :via => :post

  resources :issues do
    post :edit, :on => :member
    resources :time_entries, :controller => 'timelog'
  end

  scope 'projects/:project_id' do
    resources :issues do
      post :create, :on => :collection
      resources :time_entries, :controller => 'timelog'
    end
  end

  scope :controller => 'issue_relations', :via => :post do
    match 'issues/:issue_id/relations/:id', :action => 'new'
    match 'issues/:issue_id/relations/:id/destroy', :action => 'destroy'
  end

  match 'projects/:id/members/new' => 'members#new'

  scope :controller => 'users' do
    match 'users/:id/edit/:tab', :action => 'edit', :via => :get

    scope :via => :post do
      match 'users/:id/memberships', :action => 'edit_membership'
      match 'users/:id/memberships/:membership_id', :action => 'edit_membership'
      match 'users/:id/memberships/:membership_id/destroy', :action => 'destroy_membership'
    end
  end

  resources :users, :except => :destroy do
    member do
      post :edit_membership
      post :destroy_membership
    end
  end

  # For nice "roadmap" in the url for the index action
  match 'projects/:project_id/roadmap' => 'versions#index'

  resources :projects do
    member do
      match :copy, :via => [:get, :post]
      get :settings
      post :modules
      post :archive
      post :unarchive
    end

    resources :queries, :only => [:new, :create]
    resource :project_enumerations, :as => 'enumerations', :only => [:update, :destroy]
    resources :files, :only => [:index, :new, :create]

    resources :news, :shallow => true
    resources :time_entries, :controller => 'timelog'

    match 'wiki' => 'wiki#show', :via => :get, :as => 'wiki_start_page'
    match 'wiki/index' => 'wiki#index', :via => :get, :as => 'wiki_index'
    match 'wiki/:id/diff/:version' => 'wiki#diff', :as => 'wiki_diff'
    match 'wiki/:id/diff/:version/vs/:version_from' => 'wiki#diff', :as =>  'wiki_diff'
    match 'wiki/:id/annotate/:version' => 'wiki#annotate', :as => 'wiki_annotate'
    resources :wiki, :except => [:new, :create] do
      member do
        match :rename, :via => [:get, :post]
        get :history
        match :preview
        post :protect
        post :add_attachment
      end
      collection do
        get :export
        get :date_index
      end
    end
    resources :versions, :except => [:index, :show, :edit, :update, :destroy] do
      collection do
        put 'close_completed'
      end
    end
  end

  resources :versions, :only => [:show, :edit, :update, :destroy] do
    member do
      post :status_by
    end
  end

  # Destroy uses a get request to prompt the user before the actual DELETE request
  match 'projects/:id/destroy' => 'projects#destroy', :via => :get

  # TODO: port to be part of the resources route(s)
  scope :via => :get do
    match 'projects/:id/settings/:tab' => 'projects#settings'
    match 'projects/:project_id/issues/:copy_from/copy' => 'issues#new'
  end

  scope :controller => 'activities', :action => 'index', :via => :get do
    match 'projects/:id/activity(.:format)'
    match 'activity(.:format)'
  end

  match 'projects/:project_id/issue_categories/new' => 'issue_categories#new'
  match 'issue_categories/destroy/:id' => 'issue_categories#destroy', :id => /\d+/, :via => :post

  # those need to be after the resources :news above so that they have a lower priority
  match 'news' => 'news#index', :as => 'all_news'
  match 'news.:format' => 'news#index', :as => 'formatted_all_news'
  match 'news/preview' => 'previews#news', :as => 'preview_news'
  match 'news/:id/comments' => 'comments#create', :via => :post
  match 'news/:id/comments/:comment_id' => 'comments#destroy', :via => :delete

  scope :controller => 'repositories' do
    scope :via => :get do
      match 'projects/:id/repository', :action => 'show'
      match 'projects/:id/repository/edit', :action => 'edit'
      match 'projects/:id/repository/statistics', :action => 'stats'
      match 'projects/:id/repository/revisions(.:format)', :action => 'revisions'
      match 'projects/:id/repository/revisions/:rev', :action => 'revision'
      match 'projects/:id/repository/revisions/:rev/diff(.:format)', :action => 'diff'
      match 'projects/:id/repository/revisions/:rev/raw/*path', :action => 'entry', :format => 'raw', :rev => /[a-z0-9\.\-_]+/
      match 'projects/:id/repository/revisions/:rev/:action/*path', :rev => /[a-z0-9\.\-_]+/
      match 'projects/:id/repository/raw/*path', :action => 'entry', :format => 'raw'
      # TODO: why the following route is required?
      match 'projects/:id/repository/entry/*path', :action => 'entry'
      match 'projects/:id/repository/:action/*path'
    end
    match 'projects/:id/repository/:action', :via => :post
  end

  match 'attachments/:id' => 'attachments#show', :id => /\d+/
  match 'attachments/:id/:filename' => 'attachments#show', :id => /\d+/, :filename => /.*/
  match 'attachments/download/:id/:filename' => 'attachments#download', :id => /\d+/, :filename => /.*/
  match 'attachments/destroy/:id' => 'attachments#destroy', :id => /\d+/, :via => :post

  resources :groups

  #left old routes at the bottom for backwards compat
  match 'projects/:project_id/issues/:action', :controller => 'issues'
  match 'projects/:project_id/documents/:action', :controller => 'documents'
  match 'projects/:project_id/boards/:action/:id', :controller => 'boards'
  match 'boards/:board_id/topics/:action/:id', :controller => 'messages'
  match 'wiki/:id/:page/:action', :controller => 'wiki'
  match 'issues/:issue_id/relations/:action/:id', :controller => 'issue_relations'
  match 'projects/:project_id/news/:action', :controller => 'news'
  match 'projects/:project_id/timelog/:action/:id', :controller => 'timelog', :project_id => /.+/
  scope :controller => 'repositories' do
    match 'repositories/browse/:id/*path', :action => 'browse', :as => 'repositories_show'
    match 'repositories/changes/:id/*path', :action => 'changes', :as => 'repositories_changes'
    match 'repositories/diff/:id/*path', :action => 'diff', :as => 'repositories_diff'
    match 'repositories/entry/:id/*path', :action => 'entry', :as => 'repositories_entry'
    match 'repositories/annotate/:id/*path', :action => 'annotate', :as => 'repositories_entry'
    match 'repositories/revision/:id/:rev', :action => 'revision'
  end

  scope :controller => 'sys' do
    match 'sys/projects.:format', :action => 'projects', :via => :get
    match 'sys/projects/:id/repository.:format', :action => 'create_project_repository', :via => :post
  end

  scope :controller => 'enumerations' do
    match 'enumerations/:action(/:id)', :action => /create|update|destroy/, :id => /\d+/, :via => :post
    match 'enumerations(/:action(/:id))', :id => /\d+/ # TODO rails-3.1: limit those actions to those not defined above
  end

  scope :controller => 'issue_statuses' do
    match 'issue_statuses/:action(/:id)', :action => /destroy|create|update|move|update_issue_done_ratio/, :id => /\d+/, :via => :post
    match 'issue_statuses(/:action(/:id))', :id => /\d+/ # TODO rails-3.1: limit those actions to those not defined above
  end

  scope :controller => 'roles' do
    match 'roles/:action(/:id)', :action => /destroy|move/, :id => /\d+/, :via => :post
    match 'roles(/:action(/:id))', :id => /\d+/ # TODO rails-3.1: limit those actions to those not defined above
  end

  scope :controller => 'trackers' do
    match 'trackers/:action(/:id)', :action => /destroy/, :id => /\d+/, :via => :post
    match 'trackers(/:action(/:id))', :id => /\d+/ # TODO rails-3.1: limit those actions to those not defined above
  end

  resources :watchers, :only => [:new, :destroy] do
    member do
      post :watch
      post :unwatch
    end
  end

  match 'mail_handler' => 'mail_handler#index', :via => :post

  match 'robots.txt' => 'welcome#robots'

  # Used for OpenID
  root :to => 'account#login'
end
