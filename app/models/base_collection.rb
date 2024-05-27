# app/repositories/base_collection.rb
class BaseCollection
    def initialize(firestore = FirestoreDB)
      @firestore = firestore
    end
  
    def find(id)
      doc = collection.doc(id).get
      doc.exists? ? doc.data.merge(id: doc.document_id) : nil
    end
  
    def create(attributes)
      doc_ref = collection.add(attributes)
      doc_ref.get.data.merge(id: doc_ref.document_id)
    end
  
    def update(id, attributes)
      collection.doc(id).set(attributes, merge: true)
    end
  
    def delete(id)
      collection.doc(id).delete
    end
  
    private
  
    def collection
      @firestore.col(collection_name)
    end
  
    def collection_name
      raise NotImplementedError, "Subclasses must implement collection_name method"
    end
  end