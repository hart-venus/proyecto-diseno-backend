# app/models/professor_observer.rb
class ProfessorObserver < ActiveRecord::Observer
    def after_create(professor)
      create_user_account(professor)
      send_welcome_email(professor)
    end
  
    private
  
    def create_user_account(professor)
      # Crear la cuenta de usuario en Firebase Authentication
      firebase_user = FirebaseAuth.create_user(
        email: professor.user.email,
        password: generate_random_password
      )
  
      if firebase_user
        # Obtener el UID del usuario creado en Firebase Authentication
        uid = firebase_user.uid
  
        # Guardar el UID en el registro del usuario en la base de datos local
        professor.user.update(uid: uid)
  
        # Guardar los datos adicionales del profesor en Firestore
        FirestoreDb.collection('professors').document(uid).set(
          code: professor.code,
          phone: professor.phone,
          cellphone: professor.cellphone,
          photo_url: professor.photo_url,
          status: professor.status
        )
      else
        # Manejar el error si no se pudo crear la cuenta de usuario en Firebase Authentication
        Rails.logger.error("Failed to create Firebase user account for professor: #{professor.id}")
      end
    end
  
    def send_welcome_email(professor)
      # Enviar el correo electrónico de bienvenida al profesor
      ProfessorMailer.welcome_email(professor).deliver_now
    end
  
    def generate_random_password
      # Generar una contraseña aleatoria para la cuenta de usuario del profesor
      SecureRandom.alphanumeric(10)
    end
  end