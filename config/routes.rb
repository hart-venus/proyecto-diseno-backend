Rails.application.routes.draw do
  # Usuarios
  get '/users', to: 'users#index'
  get '/users/:id', to: 'users#show'
  post '/users', to: 'users#create'
  put '/users/:id', to: 'users#update'
  delete '/users/:id', to: 'users#destroy'
  post '/authenticate', to: 'users#authenticate'
  get '/users/find_by_campus/:campus', to: 'users#find_by_campus'
  get '/users/find_by_role/:role', to: 'users#find_by_role'
  get '/users/find_by_email/:email', to: 'users#find_by_email'

  # Rutas para el controlador de profesores
  post '/professors', to: 'professors#create'
  get '/professors/search', to: 'professors#search'
  get '/professors/:code', to: 'professors#get_professor'
  get '/professors/email/:email', to: 'professors#get_professor_by_email'
  get '/professors/campus/:campus', to: 'professors#get_professors_by_campus'
  get '/professors', to: 'professors#get_professors'
  get '/professors/active', to: 'professors#get_active_professors'
  get '/professors/inactive', to: 'professors#get_inactive_professors'
  get '/professors/:code/photo', to: 'professors#get_photo'
  put '/professors/:code', to: 'professors#update'
  get '/professors/:code/user', to: 'professors#get_professor_user'
  #delete '/professors/:id', to: 'professors#destroy'
  #put '/professors/:id/activate', to: 'professors#activate'
  #put '/professors/:id/deactivate', to: 'professors#deactivate'
  #get '/professors/find_by_campus', to: 'professors#find_by_campus'
  #get '/professors/find_by_status', to: 'professors#find_by_status'
  #get '/professors/find_by_code', to: 'professors#find_by_code'
  #put '/professors/:id/set_coordinator', to: 'professors#set_coordinator'
  #put '/professors/:id/remove_coordinator', to: 'professors#remove_coordinator'
  #post '/professors/:id/upload_photo', to: 'professors#upload_photo'

  post '/send_email', to: 'email#send_email'

end
