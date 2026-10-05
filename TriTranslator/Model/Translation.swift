//
//  Translation.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/20/25.
//

import CryptoKit
import FirebaseFirestore

struct Translation: Identifiable, Codable {
    struct Result: Codable, Equatable {
        let targetLanguage: String
        let text: String
    }

    @DocumentID var id: String?
    let sourceText: String
    let sourceLanguage: String
    let translations: [Result]
    let createdAt: Date

    /// Versioned identity for new history records. Display text and result order stay intact.
    func historyDocumentID() throws -> String {
        func normalized(_ text: String) -> String {
            text.trimmingCharacters(in: .whitespacesAndNewlines)
                .precomposedStringWithCanonicalMapping
        }

        let results = translations.map {
            [normalized($0.targetLanguage), normalized($0.text)]
        }.sorted { $0.lexicographicallyPrecedes($1) }
        // Arrays preserve field boundaries and repeated target languages without relying
        // on dictionary ordering or separators that could also occur in the text.
        let fields = [[normalized(sourceLanguage), normalized(sourceText)]] + results
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        let data = try encoder.encode(fields)
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return "v1_\(digest)"
    }

    var hasDisplayContent: Bool {
        !sourceText.isEmpty
            && !sourceLanguage.isEmpty
            && translations.count >= 2
            && translations.allSatisfy { !$0.targetLanguage.isEmpty && !$0.text.isEmpty }
    }
}

struct DeepLTranslation {
    let requestTranslation: DeepLRequestTranslation
    let responseTranslation: DeepLResponseTranslation
}

struct DeepLRequestTranslation: Codable {
    let text: [String]
    let source_lang: String?
    let target_lang: String
}

struct DeepLResponseTranslation: Codable {
    struct TranslatedText: Codable {
        let text: String
        let detected_source_language: String
    }
    
    let translations: [TranslatedText]
}
