require 'google/cloud/firestore'

if ENV['GOOGLE_APPLICATION_CREDENTIALS'].present?
    # Use the GOOGLE_APPLICATION_CREDENTIALS environment variable
    FirestoreDB = Google::Cloud::Firestore.new
else
    # Use the individual environment variables for credentials
    FirestoreDB = Google::Cloud::Firestore.new(
        project_id: ENV['GOOGLE_PROJECT_ID'],
        credentials: {
            private_key: ENV['GOOGLE_PRIVATE_KEY'].gsub('\\n', "\n"),
            client_email: ENV['GOOGLE_CLIENT_EMAIL']
        }
    )
end
