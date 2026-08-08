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

struct TranslationDisplayContent: Equatable {
    let sourceLanguage: String
    let sourceText: String
    let targetLanguage: String
    let translatedText: String
}

extension Translation {
    var displayContent: TranslationDisplayContent? {
        guard let sourceText = requestTranslation.text.first,
              let translatedText = responseTranslation?.translations.first else {
            return nil
        }

        return TranslationDisplayContent(
            sourceLanguage: translatedText.detected_source_language,
            sourceText: sourceText,
            targetLanguage: requestTranslation.target_lang,
            translatedText: translatedText.text
        )
    }
}
