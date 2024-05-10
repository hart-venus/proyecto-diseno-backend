require 'singleton'

class StorageService
  include Singleton

  def initialize
    @storage = Google::Cloud::Storage.new
    @bucket_name = 'gs://projecto-diseno-backend.appspot.com'
  end

  def upload_file(file, destination_path)
    bucket = @storage.bucket(@bucket_name)
    file_obj = bucket.create_file(file.tempfile, destination_path, content_type: file.content_type)
    file_obj.public_url
  end

  def download_file(file_path)
    bucket = @storage.bucket(@bucket_name)
    file_obj = bucket.file(file_path)
    file_obj&.download
  end

  def delete_file(file_path)
    bucket = @storage.bucket(@bucket_name)
    file_obj = bucket.file(file_path)
    file_obj&.delete
  end

end