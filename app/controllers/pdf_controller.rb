class PdfController < ApplicationController
    skip_forgery_protection
  
    def upload
      pdf = params[:pdf]
      if pdf
        begin
          public_url = upload_pdf(pdf)
          render json: { url: public_url }, status: :ok
        rescue ArgumentError => e
          render json: { error: e.message }, status: :bad_request
        end
      else
        render json: { error: 'No se proporcionó un archivo PDF' }, status: :bad_request
      end
    end
  
    private
  
    def upload_pdf(pdf)
      raise ArgumentError, "No se proporcionó un archivo PDF" unless pdf.present? && pdf.is_a?(ActionDispatch::Http::UploadedFile)

      # Nombre del bucket de Firebase Storage
      bucket_name = 'projecto-diseno-backend.appspot.com'
      bucket = FirebaseStorage.bucket(bucket_name)
  
      # Generar un nombre único para el archivo
      file_path = "pdfs/#{SecureRandom.uuid}/#{pdf.original_filename}"
  
      # Subir el archivo al bucket de Firebase Storage con permisos de lectura pública
      file = bucket.create_file(
        pdf.tempfile,
        file_path,
        content_type: pdf.content_type,
        acl: 'publicRead'
      )
  
      # Obtener la URL pública del archivo
      public_url = file.public_url
  
      public_url
    end
  end