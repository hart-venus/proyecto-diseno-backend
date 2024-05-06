Rails.application.routes.draw do
  # Usuarios
  get '/users', to: 'users#index'
  get '/users/:id', to: 'users#show'
  post '/users', to: 'users#create'
  put '/users/:id', to: 'users#update'
  delete '/users/:id', to: 'users#destroy'
  #get '/users/find_by_campus', to: 'users#find_by_campus'
  #get '/users/find_by_role', to: 'users#find_by_role'
  #get '/users/find_by_email', to: 'users#find_by_email'
  #get '/users/find_by_campus_and_role', to: 'users#find_by_campus_and_role'
  post '/authenticate', to: 'users#authenticate'

  # Rutas para el controlador de profesores
  get '/professors', to: 'professors#index'
  get '/professors/:id', to: 'professors#show'
  post '/professors', to: 'professors#create'
  put '/professors/:id', to: 'professors#update'
  delete '/professors/:id', to: 'professors#destroy'
  put '/professors/:id/activate', to: 'professors#activate'
  put '/professors/:id/deactivate', to: 'professors#deactivate'
  get '/professors/find_by_campus', to: 'professors#find_by_campus'
  get '/professors/find_by_status', to: 'professors#find_by_status'
  get '/professors/find_by_code', to: 'professors#find_by_code'
  put '/professors/:id/set_coordinator', to: 'professors#set_coordinator'
  put '/professors/:id/remove_coordinator', to: 'professors#remove_coordinator'
  post '/professors/:id/upload_photo', to: 'professors#upload_photo'

  post '/send_email', to: 'email#send_email'

end
