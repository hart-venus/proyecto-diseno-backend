require 'google/cloud/firestore'
require 'google/cloud/storage'

if Rails.env.production?
  # Use the credentials file specified by the environment variable
  credentials = JSON.parse(ENV['GOOGLE_CREDENTIALS']) if ENV['GOOGLE_CREDENTIALS']
  
  # Configure Firestore
  FirestoreDB = Google::Cloud::Firestore.new(
    credentials: credentials
  )
  
  # Configure Cloud Storage
  FirebaseStorage = Google::Cloud::Storage.new(
    credentials: credentials
  )
else
  # Development environment setup
  # Make sure to replace 'your-project-id' with your actual project ID
  FirestoreDB = Google::Cloud::Firestore.new(
    project_id: "projecto-diseno-backend",
    credentials: "credentials.json"
  )
  
  FirebaseStorage = Google::Cloud::Storage.new(
    project_id: "projecto-diseno-backend",
    credentials: "credentials.json"
  )
end