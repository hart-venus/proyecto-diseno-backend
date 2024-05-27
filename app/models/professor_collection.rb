# app/repositories/professor_collection.rb
class ProfessorCollection < BaseCollection
    def create(professor_data)
      existing_professor = find_by_email(professor_data[:email])
      if existing_professor.present?
        raise "Email already exists"
      end
      
      if professor_data[:photo].present?
        photo_url = upload_photo(professor_data[:photo])
        professor_data[:photo_url] = photo_url
      end
      
      professor = Professor.new(professor_data)
      
      if professor.valid?
        professor_ref = collection.add(professor.attributes)
        professor_ref.get.data.merge(id: professor_ref.document_id)
      else
        raise "Invalid professor data: #{professor.errors.full_messages.join(', ')}"
      end
    rescue Google::Cloud::InvalidArgumentError => e
      if e.message.include?('The query requires an index')
        index_creation_link = e.message.match(/https:\/\/.*/)
        if index_creation_link
          uri = URI(index_creation_link[0])
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          request = Net::HTTP::Post.new(uri.request_uri)
          response = http.request(request)
          if response.is_a?(Net::HTTPSuccess)
            professor_ref = collection.add(professor.attributes)
            professor_ref.get.data.merge(id: professor_ref.document_id)
          else
            Rails.logger.error("Failed to create index: #{response.body}")
            raise "Failed to create professor"
          end
        else
          Rails.logger.error("Index creation link not found in the error message")
          raise "Failed to create professor"
        end
      else
        Rails.logger.error("Firestore error: #{e.message}")
        raise "Failed to create professor"
      end
    end
    
    def update(code, professor_data)
      professor = find_by_code(code)
      if professor.present?
        professor_ref = collection.doc(professor[:id])
        previous_data = professor
        
        email_changed = false
        campus_changed = false
        
        if professor_data[:email].present? && professor_data[:email] != professor[:email]
          existing_professor = find_by_email(professor_data[:email])
          if existing_professor.present?
            raise "Email already exists"
          else
            email_changed = true
          end
        end
        
        if professor_data[:campus].present? && professor_data[:campus] != professor[:campus]
          campus_changed = true
        end
        
        if professor_data[:photo].present?
          photo_url = upload_photo(professor_data[:photo])
          professor_data[:photo_url] = photo_url
        end
        
        professor_data.each do |key, value|
          professor_ref.update({ key => value }) if value.present?
        end
        
        updated_professor = professor_ref.get.data.merge(id: professor_ref.document_id)
        
        if email_changed || campus_changed
          user_id = updated_professor[:user_id]
          user_data = { email: professor_data[:email], campus: professor_data[:campus] }
          @user_repository.update(user_id, user_data)
        end
        
        updated_professor
      else
        nil
      end
    end
    
    def toggle_coordinator(code)
      professor = find_by_code(code)
      
      if professor.present?
        professor_ref = collection.doc(professor[:id])
        
        if professor[:coordinator]
          professor_ref.update({ coordinator: false })
        else
          existing_coordinator = collection
                                .where('campus', '==', professor[:campus])
                                .where('coordinator', '==', true)
                                .get.first
          
          if existing_coordinator.present?
            raise "Another professor is already assigned as coordinator for this campus"
          end
          
          professor_ref.update({ coordinator: true })
        end
        
        professor_ref.get.data.merge(id: professor_ref.document_id)
      else
        nil
      end
    end
    
    def search(query)
      query = query&.downcase
      
      if query.present?
        professors = collection.get.to_a
        matching_professors = professors.select do |prof|
          prof.data.values.any? { |value| value.to_s.downcase.include?(query) }
        end
        
        matching_professors.map { |prof| prof.data.merge(id: prof.document_id) }
      else
        all
      end
    end
    
    def find_by_code(code)
      professor = collection.where('code', '==', code).get.first
      professor.present? ? professor.data.merge(id: professor.document_id) : nil
    end
    
    def find_by_email(email)
      professor = collection.where('email', '==', email).get.first
      professor.present? ? professor.data.merge(id: professor.document_id) : nil
    end
    
    def find_by_campus(campus)
      professors = collection.where('campus', '==', campus).get.to_a
      professors.map { |prof| prof.data.merge(id: prof.document_id) }
    end
    
    def find_active
      professors = collection.where('status', '==', 'active').get.to_a
      professors.map { |prof| prof.data.merge(id: prof.document_id) }
    end
    
    def find_inactive
      professors = collection.where('status', '==', 'inactive').get.to_a
      professors.map { |prof| prof.data.merge(id: prof.document_id) }
    end
    
    def find_user(code)
      professor = find_by_code(code)
      if professor.present? && professor[:user_id].present?
        @user_repository.find(professor[:user_id])
      else
        nil
      end
    end
    
    private
    
    def collection_name
      'professors'
    end
    
    def upload_photo(photo)
      file_path = "professors/#{SecureRandom.uuid}/#{photo.original_filename}"
      bucket_name = 'projecto-diseno-backend.appspot.com'
      bucket = FirebaseStorage.bucket(bucket_name)
      file_obj = bucket.create_file(photo.tempfile, file_path, content_type: photo.content_type)
      file_obj.public_url
    end
    
    def generate_unique_code(campus)
      campus_key = campus.to_sym
      if Professor::CAMPUSES.key?(campus_key)
        campus_code = Professor::CAMPUSES[campus_key]
        professors = collection.where('campus', '==', campus_code).order('code', 'desc').limit(1).get.to_a
        if professors.empty?
          "#{campus_code}-01"
        else
          last_professor_code = professors.first.data[:code]
          last_counter = last_professor_code.split('-').last.to_i
          new_counter = format('%02d', last_counter + 1)
          "#{campus_code}-#{new_counter}"
        end
      else
        raise ArgumentError, 'Invalid campus'
      end
    end
  end