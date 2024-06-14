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
        return true
    end

    private

    def create_user(user_data)
        user = User.new(user_data)
        return nil unless user.valid?

        user_ref = FirestoreDB.col('users').add(user_data)
        user_doc = user_ref.get
        user_doc.data.merge(id: user_doc.document_id)
    end
end
