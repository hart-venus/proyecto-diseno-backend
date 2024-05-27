# app/repositories/professor_collection.rb
class ProfessorCollection < BaseCollection
    def all
      collection.get.map { |doc| doc.data.merge(id: doc.document_id) }
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
      professors.map { |professor| professor.data.merge(id: professor.document_id) }
    end
  
    def find_by_status(status)
      professors = collection.where('status', '==', status).get.to_a
      professors.map { |professor| professor.data.merge(id: professor.document_id) }
    end
  
    def create(attributes)
      professor = Professor.new(attributes)
      if professor.valid?
        existing_professor = find_by_email(professor.email)
        if existing_professor.present?
          raise "Email already exists"
        else
          professor_data = {
            code: generate_unique_code(professor.campus),
            full_name: professor.full_name,
            email: professor.email,
            office_phone: professor.office_phone,
            cellphone: professor.cellphone,
            status: professor.status,
            coordinator: professor.coordinator,
            campus: professor.campus
          }
          doc_ref = collection.add(professor_data)
          doc_ref.get.data.merge(id: doc_ref.document_id)
        end
      else
        raise "Invalid professor data: #{professor.errors.full_messages.join(', ')}"
      end
    end
  
    def update(id, attributes)
      professor_ref = collection.doc(id)
      professor = professor_ref.get
      if professor.exists?
        professor_data = professor.data.dup
        attributes.slice(:full_name, :email, :office_phone, :cellphone, :status, :campus).each do |key, value|
          professor_data[key] = value
        end
        if attributes[:coordinator].present?
          professor_data[:coordinator] = attributes[:coordinator]
        end
        professor_ref.set(professor_data)
        professor_ref.get.data.merge(id: professor_ref.document_id)
      else
        nil
      end
    end
  
    def toggle_coordinator(id)
      professor_ref = collection.doc(id)
      professor = professor_ref.get
      if professor.exists?
        current_coordinator_status = professor.data[:coordinator]
        professor_ref.update({ coordinator: !current_coordinator_status })
        professor_ref.get.data.merge(id: professor_ref.document_id)
      else
        nil
      end
    end
  
    private
  
    def collection_name
      'professors'
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