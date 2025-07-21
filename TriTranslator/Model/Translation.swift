//
//  Translation.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/20/25.
//

import FirebaseFirestore

struct Translation: Identifiable, Codable {
    @DocumentID var id: String?
    let requestTranslation: DeepLRequestTranslation
    var responseTranslation: DeepLResponseTranslation?
    let createdAt: Date
}

struct DeepLRequestTranslation: Codable {
    let text: [String]
    let target_lang: String
}

struct DeepLResponseTranslation: Codable {
    struct TranslatedText: Codable {
        let text: String
        let detected_source_language: String
    }
    
    let translations: [TranslatedText]
}

