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
    # Listar actividades de un plan de trabajo
  get '/activities', to: 'activities#index'

  get '/activity/notified', to: 'activities#notified'

  # Mostrar detalles de una actividad
  get '/activities/:id', to: 'activities#show'

  # Obtener poster de una actividad
  get '/activities/:id/poster', to: 'activities#poster'

  # Crear una nueva actividad
  post '/activities', to: 'activities#create'

  # Actualizar una actividad existente
  put '/activities/:id', to: 'activities#update'
  patch '/activities/:id', to: 'activities#update'

  # Agregar evidencia a una actividad
  post '/activities/:id/evidences', to: 'activities#add_evidence'

  # Activar una actividad
  post '/activities/:id/activate', to: 'activities#activate'

  # Notificar una actividad
  patch '/activities/:id/notify', to: 'activities#notify'

  # Marcar una actividad como realizada
  post '/activities/:id/done', to: 'activities#mark_as_done'

  # Cancelar una actividad
  post '/activities/:id/cancel', to: 'activities#cancel'

  # Agregar Comentarios
  post '/comments/:activity_id', to: 'activity_comments#create'

  get '/comments/:activity_id/base_comments' , to: 'activity_comments#activity_base_comments'

  get '/comments/:parent_comment_id/replies' , to: 'activity_comments#direct_reply_comments'

  # Rutas para el controlador de GlobalSystemDates

  get 'system_date', to: 'system_dates#show'
  put 'system_date', to: 'system_dates#update'
  post 'system_date/increment', to: 'system_dates#increment'
  post 'system_date/decrement', to: 'system_dates#decrement'


  # Ruta para listar las notificaciones de un estudiante específico
  get '/students/:student_carne/notifications', to: 'notifications#index', as: 'student_notifications'

  # Ruta para crear una nueva notificación para un estudiante específico
  post '/students/:student_carne/notifications', to: 'notifications#create', as: 'create_student_notification'

  # Ruta para marcar una notificación como leída para un estudiante específico
  post '/students/:student_carne/notifications/:id/mark_as_read', to: 'notifications#mark_as_read', as: 'mark_as_read_student_notification'

  # Ruta para eliminar una notificación para un estudiante específico
  delete '/students/:student_carne/notifications/:id', to: 'notifications#destroy', as: 'destroy_student_notification'

  # Ruta para enviar una notificación a todos los estudiantes de un campus específico
  post '/send_notification_to_campus', to: 'notifications#send_notification_to_campus', as: 'send_notification_to_campus'

end


