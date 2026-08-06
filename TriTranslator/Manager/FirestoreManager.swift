//
//  FirestoreManager.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/19/25.
//

import FirebaseAuth
import FirebaseFirestore

enum FirestoreManagerError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to access translation history."
        }
    }
}

@MainActor
final class FirestoreManager: ObservableObject {
    private let db = Firestore.firestore()

    @Published private(set) var translations = [Translation]()

    func addTranslation(_ translation: Translation) throws {
        let userID = try authenticatedUserID()
        try translationsCollection(for: userID).addDocument(from: translation)
    }

    func getTranslations() async throws {
        translations = []
        let userID = try authenticatedUserID()
        let querySnapshot = try await translationsCollection(for: userID)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        guard Auth.auth().currentUser?.uid == userID else {
            throw FirestoreManagerError.notAuthenticated
        }

        translations = querySnapshot.documents.compactMap { document in
            try? document.data(as: Translation.self)
        }
    }

    func clearTranslations() {
        translations = []
    }

    private func authenticatedUserID() throws -> String {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw FirestoreManagerError.notAuthenticated
        }

        return userID
    }

    private func translationsCollection(for userID: String) -> CollectionReference {
        db.collection("users")
            .document(userID)
            .collection("translations")
    }
}
