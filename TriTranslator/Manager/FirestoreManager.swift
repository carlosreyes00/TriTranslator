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
    case invalidSaveResult

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to access translation history."
        case .invalidSaveResult:
            return "The translation save result could not be confirmed."
        }
    }
}

enum TranslationSaveResult: String {
    case saved
    case alreadyExists
}

@MainActor
final class FirestoreManager: ObservableObject {
    private lazy var db = Firestore.firestore()
    private var translationsRequestID: UUID?

    @Published private(set) var translations = [Translation]()
    @Published private(set) var skippedTranslationCount = 0

    func addTranslation(_ translation: Translation) async throws -> TranslationSaveResult {
        try Task.checkCancellation()
        let userID = try authenticatedUserID()
        let document = translationsCollection(for: userID)
            .document(try translation.historyDocumentID())
        let data = try Firestore.Encoder().encode(translation)
        let result = try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(document)
                if snapshot.exists {
                    return TranslationSaveResult.alreadyExists.rawValue
                }
                transaction.setData(data, forDocument: document)
                return TranslationSaveResult.saved.rawValue
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        try Task.checkCancellation()
        guard Auth.auth().currentUser?.uid == userID else {
            throw FirestoreManagerError.notAuthenticated
        }
        guard let rawValue = result as? String,
              let saveResult = TranslationSaveResult(rawValue: rawValue) else {
            throw FirestoreManagerError.invalidSaveResult
        }
        return saveResult
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
