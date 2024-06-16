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
  post '/users/recover_password', to: 'users#recover_password'
  
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
  get 'work_plan/active', to: 'work_plans#active'
  get 'work_plan/inactive', to: 'work_plans#inactive'
  get '/work_plans/:id_p', to: 'work_plans#show'
  post '/work_plans', to: 'work_plans#create'
  put '/work_plans/:id', to: 'work_plans#update'

  # Endpoints para actividades (Activities)
  # Para buscar actividades por id de plan de trabajo
  get 'activities', to: 'activities#index'

  # Para buscar actividades por id
  get 'activities/:id', to: 'activities#show'

  # Para crear una actividad
  post 'activities', to: 'activities#create'

  # Para actualizar una actividad
  put 'activities/:id', to: 'activities#update'

  # aGREGAR EVIDENCIA
  post 'activities/:id/add_evidence', to: 'activities#add_evidence'
  post 'activities/:id/activate', to: 'activities#activate'
  post 'activities/send_reminders', to: 'activities#send_reminders'
  post 'activities/:id/mark_as_done', to: 'activities#mark_as_done'
  post 'activities/:id/cancel', to: 'activities#cancel'
  get 'activities/notified', to: 'activities#notified'
  get 'activities/:id/poster', to: 'activities#poster'
  get 'activities/:id/should_notify', to: 'activities#should_notify'

  # Agregar Comentarios
  post '/comments/:activity_id', to: 'activity_comments#create'

  get '/comments/:activity_id/base_comments' , to: 'activity_comments#activity_base_comments'

  get '/comments/:parent_comment_id/replies' , to: 'activity_comments#direct_reply_comments'

  # Rutas para el controlador de GlobalSystemDates

  get 'system_date', to: 'system_dates#show'
  put 'system_date', to: 'system_dates#update'
  post 'system_date/increment', to: 'system_dates#increment'
  post 'system_date/decrement', to: 'system_dates#decrement'


  get 'student_inbox/:student_carne', to: 'student_inbox#show'
  get 'student_inbox/:student_carne/fuzzy_search', to: 'student_inbox#fuzzy_search'
  get 'student_inbox/:student_carne/filter_by_status', to: 'student_inbox#filter_by_status'

  put 'student_inbox/:student_carne/notifications/:notification_id/mark_as_read', to: 'student_inbox#mark_as_read'
  delete 'student_inbox/:student_carne/notifications/:notification_id', to: 'student_inbox#destroy'

end


