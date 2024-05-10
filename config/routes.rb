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
  put '/professors/:code/profile', to: 'professors#update_profile'
  put '/professors/:code/toggle_coordinator', to: 'professors#toggle_coordinator'
  get '/professors/:code/user', to: 'professors#get_professor_user'

  # Rutas para el controlador de Estudiantes
  post '/students/upload', to: 'students#upload'
  get '/students/export', to: 'students#export_to_excel' 
  get '/students', to: 'students#index'
  get '/students/by_name', to: 'students#index_by_name'
  get '/students/by_carne', to: 'students#index_by_carne'
  get '/students/by_campus', to: 'students#index_by_campus'
  get '/students/search', to: 'students#fuzzy_search'
  get '/students/:id', to: 'students#show'
  put '/students/:id', to: 'students#update'
  delete '/students/:id', to: 'students#destroy'

  # Planes de trabajo
  get '/work_plans', to: 'work_plans#index'
  get '/work_plans/:id', to: 'work_plans#show'
  post '/work_plans', to: 'work_plans#create'
  put '/work_plans/:id', to: 'work_plans#update'
  delete '/work_plans/:id', to: 'work_plans#destroy'
  get '/work_plans/:id/activities', to: 'work_plans#activities'
  
  # Actividades
  post '/activities', to: 'activities#create'


end


