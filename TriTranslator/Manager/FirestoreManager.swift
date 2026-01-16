//
//  FirestoreManager.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/19/25.
//

import FirebaseFirestore

@preconcurrency
class FirestoreManager: ObservableObject {
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
        let querySnapshot = try await db.collection("translations").order(by: "createdAt", descending: true).getDocuments()
        
        let translations = querySnapshot.documents.compactMap { document in
            try? document.data(as: Translation.self)
        }
        
        DispatchQueue.main.async { [self] in
            self.translations = translations
        }
    }
    
    func startListening() {
        listener = db.collection("translations")
            .order(by: "createdAt", descending: true)
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
