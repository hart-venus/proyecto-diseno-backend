require 'roo'

class StudentsController < ApplicationController
  skip_forgery_protection

  # Método para subir y procesar el archivo Excel de estudiantes
  def upload
    file = params[:file]
    admin_id = params[:admin_id]

    # Verificar que se haya seleccionado un archivo
    if file.nil?
      render json: { error: 'No file selected' }, status: :bad_request
      return
    end

    # Verificar que el archivo tenga la extensión .xlsx
    unless File.extname(file.original_filename) == '.xlsx'
      render json: { error: 'Invalid file format. Only .xlsx files are allowed' }, status: :bad_request
      return
    end

    # Verificar que se haya proporcionado el ID de la asistente administrativa
    if admin_id.nil?
      render json: { error: 'Admin ID is required' }, status: :bad_request
      return
    end

    # Buscar la asistente administrativa por su ID
    admin = User.find_by_id(admin_id)

    # Verificar que la asistente administrativa exista
    if admin.nil?
      render json: { error: 'Admin not found' }, status: :not_found
      return
    end

    # Obtener el campus de la asistente administrativa
    admin_campus = admin.campus

    # Leer el archivo Excel
    begin
      xlsx = Roo::Excelx.new(file.tempfile)
      sheet = xlsx.sheet(0) # Assuming the data is in the first sheet

      # Obtener los nombres de las columnas desde la primera fila
      headers = sheet.row(1).map(&:strip)

      # Verificar que el archivo tenga las columnas requeridas
      required_columns = ['Carne', 'Nombre Completo', 'Correo Electrónico', 'Número de Celular']
      missing_columns = required_columns - headers
      if missing_columns.any?
        render json: { error: "Missing columns: #{missing_columns.join(', ')}" }, status: :bad_request
        return
      end

      # Procesar los datos de los estudiantes
      students_data = []
      (2..sheet.last_row).each do |i|
        row = sheet.row(i)
        student_data = {
          carne: row[headers.index('Carne')],
          full_name: row[headers.index('Nombre Completo')],
          email: row[headers.index('Correo Electrónico')],
          phone: row[headers.index('Número de Celular')],
          campus: admin_campus
        }
        students_data << student_data
      end

      # Crear los estudiantes en la base de datos
      created_students = []
      students_data.each do |data|
        student = Student.new(data)
        if student.save
          created_students << student
        else
          render json: { error: "Error creating student with carne #{data[:carne]}: #{student.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
          return
        end
      end

      render json: { message: "Successfully created #{created_students.count} students", students: created_students }, status: :created
    rescue => e
      render json: { error: "Error processing the file: #{e.message}" }, status: :internal_server_error
    end
  end

  # Método para obtener la lista de estudiantes ordenada por nombre completo
  def index_by_name
    students = Student.all.order(:full_name)
    render json: students
  end

  # Método para obtener la lista de estudiantes ordenada por número de carné
  def index_by_carne
    students = Student.all.order(:carne)
    render json: students
  end

  # Método para obtener la lista de estudiantes ordenada por campus
  def index_by_campus
    students = Student.all.order(:campus)
    render json: students
  end
end