//
//  Translation.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/20/25.
//

import FirebaseFirestore

struct Translation: Identifiable, Codable {
    @DocumentID var id: String?
    let sourceText: String
    let translatedText: String
    let sourceLang: String
    let targetLang: String
    let createdAt: Date
}
