class StudentDecorator < Student
    attr_accessor :user_id, :photo_url # nuevos fields de los cuales se encargará el decorator

    def initialize(attributes = {}) # se inicializa el decorator con los atributos del modelo
        super(attributes)
        @user_id = attributes[:user_id]
        @photo_url = attributes[:photo_url] || ''
    end

    def save
        student_ref = super
        return false unless student_ref # si no se guarda el estudiante, no se guarda el decorador

        secure_pass = BCrypt::Password.create(@carne) # el carnet es la contraseña por defecto
        user_data = {
            email: @email,
            full_name: full_name,
            role: User::ROLES[:student],
            campus: @campus,
            password: secure_pass
        }

        user = create_user(user_data)
        return false unless user.present?

        @user_id = user[:id]
        student_ref.set({user_id: @user_id, photo_url: @photo_url}, merge: true)

        # Crear un inbox asociado al estudiante
        create_student_inbox

        return true

        
    end

    def update(attributes)
        student_ref = super
        return false unless student_ref # si no se actualiza el estudiante, no se actualiza el decorador
        # los fields de la clase Student se actualizan en la superclase
        # falta actualizar password en User y photo_url en Student
        user_ref = FirestoreDB.col('users').doc(@user_id)
        # Asegurar paridad entre user y student
        user_ref.set({full_name: full_name, campus: @campus, email: @email}, merge: true)
        # si attributes tiene la llave :password, se actualiza el password
        if attributes[:password].present?
            secure_pass = BCrypt::Password.create(attributes[:password])
            user_ref.set({password: secure_pass}, merge: true)
        end
        # si attributes tiene la llave :photo, se actualiza la foto
        if attributes[:photo].present?
            photo_url = upload_photo(attributes[:photo])
            student_ref.set({photo_url: photo_url}, merge: true)
        end

        true
    end

    private

    def create_user(user_data)
        user = User.new(user_data)
        return nil unless user.valid?

        user_ref = FirestoreDB.col('users').add(user_data)
        user_doc = user_ref.get
        user_doc.data.merge(id: user_doc.document_id)
    end

    def upload_photo(photo)
        file_path = "students/#{SecureRandom.uuid}/#{photo.original_filename}"
        bucket_name = 'projecto-diseno-backend.appspot.com'
        bucket = FirebaseStorage.bucket(bucket_name)
        file_obj = bucket.create_file(photo.tempfile, file_path, content_type: photo.content_type)
        file_obj.public_url
    end

    def create_student_inbox
        inbox = StudentInbox.new(student_carne: @carne)
        inbox.save
      end
end
