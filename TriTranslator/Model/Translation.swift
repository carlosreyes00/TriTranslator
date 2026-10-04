//
//  Translation.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/20/25.
//

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
