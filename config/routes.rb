Rails.application.routes.draw do

  #map.openid_server 'openid_server', :controller => 'openid_server'
  resource :openid_server

#TODO
  get 'session/open_id_complete', :to => 'sessions#create', :open_id_complete => true, :as => 'open_id_complete'
  #map.open_id_complete 'session/open_id_complete',
  #                     { :controller => 'sessions',
  #                       :action     => 'create',
  #                       :conditions => { :method => :get },
  #                       :open_id_complete => true }

  resource :session

  match 'caclogin', :to => 'sessions#create', :as => 'login'
  match 'login', :to => 'sessions#new', :as => 'login'
  match 'logout', :to => 'sessions#destroy', :as => 'logout'

  if ActiveRecord::Agent.activation_class
    match 'activate/:activation_code', :to => "#{ActiveRecord::Agent.activation_class.to_s.tableize}#activate",
      :as => 'activate', :activation_code => nil
    #map.activate 'activate/:activation_code',
    #         :controller => ActiveRecord::Agent.activation_class.to_s.tableize,
    #         :action => 'activate',
    #         :activation_code => nil

    match 'lost_password', :to => "#{ActiveRecord::Agent.activation_class.to_s.tableize}#lost_password",
      :as => 'lost_password'
    #map.lost_password 'lost_password',
    #                :controller => ActiveRecord::Agent.activation_class.to_s.tableize,
    #                :action => 'lost_password'
    match 'reset_password/:reset_password_code', :to => "#{ActiveRecord::Agent.activation_class.to_s.tableize}#reset_password",
      :as => 'reset_password', :reset_password_code => nil
    #map.reset_password 'reset_password/:reset_password_code',
    #               :controller => ActiveRecord::Agent.activation_class.to_s.tableize,
    #               :action => 'reset_password',
    #               :reset_password_code => nil
  end

  if ActiveRecord::Agent::authentication_classes(:openid).any?
    resources :open_id_ownings
  end

  resources :tags

  resource :site do
    if Site.table_exists?
# TODO
      with_options :requirements => { :site_id => Site.current.id } do
        resources :performances
        resources *ActiveRecord::Resource.symbols
      end
#
    end
  end

  resources *( ( ActiveRecord::Resource.symbols |
                 ActiveRecord::Content.symbols  |
                 ActiveRecord::Agent.symbols ) -
                 ActiveRecord::Container.symbols )

  ActiveRecord::Container.symbols.each do |container_sym|
    next if container_sym == :sites
    resources container_sym do
      resources(*container_sym.to_class.contents)
      resources :sources do
        get :import, :as => :member
      end
      resources :tags
    end
  end
  resources :sources do
    get :import, :as => :member
  end

  resources :logos

  resources(*(ActiveRecord::Logoable.symbols - Array(:sites))) do
    resource :logo
  end

  resources :roles
  resources :invitations do
    get :accept, :as => :member
  end

  resources(*ActiveRecord::Stage.symbols - Array(:sites)) do
    resources :performances
    resources :invitations
    resources :join_requests
  end

  resources :performances
end
