Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Autenticación
      post '/login', to: 'authentication#login'
      post '/signup', to: 'authentication#signup'

      # Usuarios
      get '/users', to: 'users#index'
      get '/users/:id', to: 'users#show'
      patch '/users/:id', to: 'users#update'

      # Profesores Guía
      get '/profesores', to: 'professors#index'
      get '/profesores/:id', to: 'professors#show'
      post '/profesores', to: 'professors#create'
      patch '/profesores/:id', to: 'professors#update'
      delete '/profesores/:id', to: 'professors#destroy'
      post '/profesores/:id/coordinador', to: 'professors#assign_coordinator'

      # Estudiantes
      post '/estudiantes/cargar', to: 'students#load_data'
      get '/estudiantes', to: 'students#index'
      get '/estudiantes/:id', to: 'students#show'
      patch '/estudiantes/:id', to: 'students#update'

      # Planes de Trabajo
      get '/planes', to: 'plans#index'
      get '/planes/:id', to: 'plans#show'
      post '/planes', to: 'plans#create'
      patch '/planes/:id', to: 'plans#update'

      # Actividades
      get '/actividades', to: 'activities#index'
      get '/actividades/:id', to: 'activities#show'
      post '/actividades', to: 'activities#create'
      patch '/actividades/:id', to: 'activities#update'
      delete '/actividades/:id', to: 'activities#destroy'

      # Comentarios
      post '/actividades/:activity_id/comentarios', to: 'comments#create'
      post '/actividades/:activity_id/comentarios/:comment_id/respuestas', to: 'comments#create_reply'

      # Reportes
      get '/reportes/estudiantes', to: 'reports#students'
      get '/reportes/estudiantes/:campus', to: 'reports#students_by_campus'
    end
  end
end