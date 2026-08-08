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
    private lazy var db = Firestore.firestore()
    private var translationsRequestID: UUID?

    @Published private(set) var translations = [Translation]()
    @Published private(set) var skippedTranslationCount = 0

    func addTranslations(_ translations: [Translation]) async throws {
        guard !translations.isEmpty else {
            return
        }

        let userID = try authenticatedUserID()
        let collection = translationsCollection(for: userID)
        let batch = db.batch()

        for translation in translations {
            try batch.setData(from: translation, forDocument: collection.document())
        }

        try await batch.commit()
    }

    func getTranslations() async throws {
        let requestID = UUID()
        translationsRequestID = requestID
        translations = []
        skippedTranslationCount = 0
        defer {
            if translationsRequestID == requestID {
                translationsRequestID = nil
            }
        }

        let userID = try authenticatedUserID()
        let querySnapshot = try await translationsCollection(for: userID)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        try Task.checkCancellation()

        guard translationsRequestID == requestID else {
            throw CancellationError()
        }

        guard Auth.auth().currentUser?.uid == userID else {
            throw FirestoreManagerError.notAuthenticated
        }

        var decodedTranslations = [Translation]()
        var invalidDocumentCount = 0

        for document in querySnapshot.documents {
            try Task.checkCancellation()

            do {
                decodedTranslations.append(try document.data(as: Translation.self))
            } catch {
                invalidDocumentCount += 1
            }
        }

        guard translationsRequestID == requestID else {
            throw CancellationError()
        }

        translations = decodedTranslations
        skippedTranslationCount = invalidDocumentCount
    }

    func clearTranslations() {
        translationsRequestID = nil
        translations = []
        skippedTranslationCount = 0
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
