require 'roo'
require 'axlsx'

# app/controllers/students_controller.rb
class StudentsController < ApplicationController
  skip_forgery_protection


  # Actualizar un estudiante
  def update
    student = Student.find(params[:id])
    
    if student.nil?
      render json: { error: 'Estudiante no encontrado' }, status: :not_found
      return
    end

    if student.update(student_params)
      render json: student_response(student)
    else
      render json: { error: student.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  # Eliminar un estudiante
  def destroy
    student = Student.find(params[:id])
    
    if student.nil?
      render json: { error: 'Estudiante no encontrado' }, status: :not_found
      return
    end

    if student.destroy
      render json: { message: 'Estudiante eliminado exitosamente' }, status: :ok
    else
      render json: { error: 'Error al eliminar el estudiante' }, status: :unprocessable_entity
    end
  end

  # Método para subir y procesar el archivo Excel de estudiantes
  def upload
    file = params[:file]
    admin_id = params[:admin_id]

    # Verificar que se haya seleccionado un archivo
    if file.nil?
      render json: { error: 'No se seleccionó ningún archivo' }, status: :bad_request
      return
    end

    # Verificar que el archivo tenga la extensión .xlsx
    unless File.extname(file.original_filename) == '.xlsx'
      render json: { error: 'Formato de archivo inválido. Solo se permiten archivos .xlsx' }, status: :bad_request
      return
    end

    # Verificar que se haya proporcionado el ID de la asistente administrativa
    if admin_id.nil?
      render json: { error: 'Se requiere el ID de la asistente administrativa' }, status: :bad_request
      return
    end

    # Buscar la asistente administrativa por su ID
    admin = User.find_by_id(admin_id)

    # Verificar que la asistente administrativa exista
    if admin.nil?
      render json: { error: 'Asistente administrativa no encontrada' }, status: :not_found
      return
    end

    # Obtener el campus de la asistente administrativa
    admin_campus = admin.campus

    # Leer el archivo Excel
    begin
      xlsx = Roo::Spreadsheet.open(file.tempfile)
      sheet = xlsx.sheet(0)

      # Obtener los nombres de las columnas desde la primera fila
      headers = sheet.row(1).map(&:strip)

      # Verificar que el archivo tenga las columnas requeridas
      required_columns = ['Carne', 'Nombre Completo', 'Correo Electrónico', 'Número de Celular']
      missing_columns = required_columns - headers
      if missing_columns.any?
        render json: { error: "Faltan las siguientes columnas: #{missing_columns.join(', ')}" }, status: :bad_request
        return
      end

      # Procesar los datos de los estudiantes
      created_students = []
      sheet.each_with_index(carne: 'Carne', full_name: 'Nombre Completo', email: 'Correo Electrónico', phone: 'Número de Celular') do |row, row_index|
        # Saltar la primera fila (encabezados)
        next if row_index == 0

        # Imprimir los datos de la fila antes de procesarla
        puts "Fila #{row_index}:"
        puts "Carne: #{row[:carne]}"
        puts "Nombre Completo: #{row[:full_name]}"
        puts "Correo Electrónico: #{row[:email]}"
        puts "Número de Celular: #{row[:phone]}"
        puts "---"

        # Verificar si el estudiante ya existe en la base de datos
        existing_student = Student.find(row[:carne])
        next if existing_student.present?

        full_name_parts = row[:full_name].split(' ')
        last_name1 = full_name_parts[0]
        last_name2 = full_name_parts[1]
        name1 = full_name_parts[2]
        name2 = full_name_parts[3..-1].join(' ') if full_name_parts.length > 3

        student = Student.new(
          carne: row[:carne],
          last_name1: last_name1,
          last_name2: last_name2,
          name1: name1,
          name2: name2,
          email: row[:email],
          phone: row[:phone],
          campus: admin_campus
        )

        if student.save
          created_students << student
        else
          Rails.logger.error("Error al crear estudiante con carné #{row[:carne]}: #{student.errors.full_messages.join(', ')}")
          render json: { error: "Error al crear estudiante con carné #{row[:carne]}: #{student.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
          return
        end
      end

      # Generar la respuesta JSON con los atributos necesarios de cada estudiante
      students_response = created_students.map do |student|
        {
          carne: student.carne,
          full_name: student.full_name,
          email: student.email,
          phone: student.phone,
          campus: student.campus
        }
      end

      render json: { message: "Se crearon exitosamente #{created_students.count} estudiantes", students: students_response }, status: :created
    rescue => e
      Rails.logger.error("Error al procesar el archivo: #{e.message}")
      render json: { error: "Error al procesar el archivo: #{e.message}" }, status: :internal_server_error
    end
  end

  # Listar todos los estudiantes
  def index
    students = FirestoreDB.col('students').get.map { |student_doc| Student.new(student_doc.data.merge(id: student_doc.document_id)) }
    render json: students.map { |student| student_response(student) }
  end


  # Obtener la lista de estudiantes ordenada por nombre completo
  def index_by_name
    students = FirestoreDB.col('students').order_by('last_name1').order_by('last_name2').order_by('name1').order_by('name2').get
    render json: students.map { |student_doc| student_response(Student.new(student_doc.data.merge(id: student_doc.document_id))) }
  end

  # Obtener la lista de estudiantes ordenada por número de carné
  def index_by_carne
    students = FirestoreDB.col('students').order_by('carne').get
    render json: students.map { |student_doc| student_response(Student.new(student_doc.data.merge(id: student_doc.document_id))) }
  end

  # Obtener la lista de estudiantes ordenada por campus
  def index_by_campus
    students = FirestoreDB.col('students').order_by('campus').get
    render json: students.map { |student_doc| student_response(Student.new(student_doc.data.merge(id: student_doc.document_id))) }
  end

  def fuzzy_search
    query = params[:query].downcase
    
    if query.present?
      students = FirestoreDB.col('students').get.select do |student_doc|
        student = Student.new(student_doc.data.merge(id: student_doc.document_id))
        student.carne.to_s.include?(query) ||
        student.last_name1.downcase.include?(query) ||
        student.last_name2.downcase.include?(query) ||
        student.name1.downcase.include?(query) ||
        student.name2.downcase.include?(query) ||
        student.email.downcase.include?(query) ||
        student.phone.to_s.include?(query) ||
        student.campus.downcase.include?(query)
      end
      
      if students.empty?
        render json: { message: 'No se encontraron estudiantes que coincidan con la búsqueda' }, status: :not_found
      else
        render json: students.map { |student_doc| student_response(Student.new(student_doc.data.merge(id: student_doc.document_id))) }
      end
    else
      render json: { error: 'Debe proporcionar un término de búsqueda' }, status: :bad_request
    end
  end

  def export_to_excel
    campus = params[:campus]
    
    if campus.present?
      # Si se proporciona un campus específico, obtener los estudiantes de ese campus
      students = FirestoreDB.col('students').where('campus', '==', campus).get.map do |student_doc|
        Student.new(student_doc.data.merge(id: student_doc.document_id))
      end
    else
      # Si no se proporciona un campus, obtener todos los estudiantes
      students = FirestoreDB.col('students').get.map do |student_doc|
        Student.new(student_doc.data.merge(id: student_doc.document_id))
      end
    end
    
    # Crear un nuevo paquete de Excel
    package = Axlsx::Package.new
    workbook = package.workbook
    
    if campus.present?
      # Si se proporciona un campus, crear una hoja de cálculo para ese campus
      create_worksheet(workbook, "Estudiantes - #{campus}", students)
    else
      # Si no se proporciona un campus, crear una hoja de cálculo para cada campus
      Constants::CAMPUSES.each do |campus_key, campus_value|
        campus_students = students.select { |student| student.campus == campus_value }
        
        # Saltar al siguiente campus si no hay estudiantes para el campus actual
        next if campus_students.empty?
        
        create_worksheet(workbook, "Estudiantes - #{campus_value}", campus_students)
      end
    end
  
    # Enviar el archivo Excel como respuesta
    send_data package.to_stream.read, type: "application/xlsx", filename: "estudiantes.xlsx"
  end
  
  def create_worksheet(workbook, name, students)
    # Crear una nueva hoja de cálculo con el nombre especificado
    workbook.add_worksheet(name: name) do |sheet|
      # Agregar la fila de encabezado con los títulos de columna
      sheet.add_row ["Carne", "Nombre Completo", "Correo Electrónico", "Número de Celular", "Campus"]
      
      # Agregar una fila por cada estudiante
      students.each do |student|
        sheet.add_row [
          student.carne,
          student.full_name,
          student.email,
          student.phone,
          student.campus
        ]
      end
    end
  end

  # Detalles de un estudiante
  def show
    student = Student.find(params[:id])
    if student.present?
      render json: student_response(student)
    else
      render json: { error: 'Estudiante no encontrado' }, status: :not_found
    end
  end

  private
  def student_response(student)
    {
      carne: student.carne,
      full_name: student.full_name,
      email: student.email,
      phone: student.phone,
      campus: student.campus
    }
  end
  def student_params
    params.permit(:last_name1, :last_name2, :name1, :name2, :email, :phone, :campus)
  end
end