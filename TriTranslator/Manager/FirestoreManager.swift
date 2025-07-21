//
//  FirestoreManager.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/19/25.
//

import FirebaseFirestore

@preconcurrency
@Observable class FirestoreManager {
    private var db = Firestore.firestore()
    
    var translations = [Translation]()
    
    private var listener: ListenerRegistration?
    
    init() {
        startListening()
    }
    
    func addTranslation(_ translation: Translation) {
        do {
            try db.collection("translations").addDocument(from: translation)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func getTranslations() async throws {
        let querySnapshot = try await db.collection("translations").order(by: "createdAt").getDocuments()
        
        let translations = querySnapshot.documents.compactMap { document in
            try? document.data(as: Translation.self)
        }
        
        DispatchQueue.main.async { [self] in
            self.translations = translations
        }
    }
    
    func startListening() {
        listener = db.collection("translations")
            .order(by: "createdAt")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to workouts: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let translations = documents.compactMap { document in
                    try? document.data(as: Translation.self)
                }
                
                DispatchQueue.main.async { [self] in
                    self.translations = translations
                }
            }
    }
    
    deinit {
        listener?.remove()
    }
    
    
}
