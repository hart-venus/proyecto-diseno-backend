# app/repositories/user_collection.rb
class UserCollection < BaseCollection
    def all
        collection.get.map { |doc| doc.data.merge(id: doc.document_id) }
      end

    def find_by_email(email)
      user = collection.where('email', '==', email).get.to_a
      user.present? ? user.data.merge(id: user.document_id) : nil
    end
  
    def find_by_campus(campus)
      users = collection.where('campus', '==', campus).get.to_a
      users.map { |user| user.data.merge(id: user.document_id) }
    end
  
    def find_by_role(role)
      users = collection.where('role', '==', role).get.to_a
      users.map { |user| user.data.merge(id: user.document_id) }
    end
  
    def create(attributes)
      user = User.new(attributes)
      if user.valid?
        existing_user = find_by_email(user.email)
        if existing_user.present?
          raise "Email already exists"
        else
          user_data = {
            email: user.email,
            full_name: user.full_name,
            role: user.role,
            campus: user.campus,
            password: encrypt_password(user.password)
          }
          doc_ref = collection.add(user_data)
          doc_ref.get.data.merge(id: doc_ref.document_id)
        end
      else
        raise "Invalid user data: #{user.errors.full_messages.join(', ')}"
      end
    end
  
    def update(id, attributes)
      user_ref = collection.doc(id)
      user = user_ref.get
  
      if user.exists?
        user_data = user.data.dup
  
        if attributes[:password].present?
          user_data[:password] = encrypt_password(attributes[:password])
        end
  
        attributes.slice(:full_name, :role, :campus).each do |key, value|
          user_data[key] = value
        end
  
        if attributes[:email].present? && attributes[:email] != user_data[:email]
          existing_user = find_by_email(attributes[:email])
          if existing_user.present?
            raise "Email already exists"
          else
            user_data[:email] = attributes[:email]
          end
        end
  
        user_ref.set(user_data)
        user_ref.get.data.merge(id: user_ref.document_id)
      else
        nil
      end
    end
  
    def authenticate(email, password)
      user = find_by_email(email)
      user.present? && password_match?(user[:password], password) ? user : nil
    end
  
    def create_with_password(attributes)
      password = SecureRandom.base64(10)
      attributes[:password] = encrypt_password(password)
      user = create(attributes)
      { user: user, password: password }
    end
  
    def update_password(id, password)
      encrypted_password = encrypt_password(password)
      update(id, { password: encrypted_password })
    end
  
    def recover_password(email)
      user = find_by_email(email)
      if user.present?
        temporary_password = SecureRandom.base64(10)
        update_password(user[:id], temporary_password)
        ProfessorMailer.password_recovery_email(user, email, temporary_password).deliver_now
        temporary_password
      else
        nil
      end
    end
  
    private
  
    def collection_name
      'users'
    end
  
    def encrypt_password(password)
      BCrypt::Password.create(password)
    end
  
    def password_match?(encrypted_password, plain_password)
      BCrypt::Password.new(encrypted_password) == plain_password
    end
  end