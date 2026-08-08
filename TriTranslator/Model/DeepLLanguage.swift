//
//  DeepLLanguage.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/22/25.
//

import Foundation

struct DeepLLanguage: Codable, Identifiable, Equatable, Hashable {
    let id = UUID()
    
    let language: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case language = "language"
        case name = "name"
    }

    static func saveLanguagesToDisk(languages: [DeepLLanguage]) {
        guard let url = languagesFileURL,
              let data = try? JSONEncoder().encode(languages) else {
            return
        }

        try? data.write(to: url, options: .atomic)
    }

    static func loadLanguagesFromDisk() -> [DeepLLanguage] {
        guard let url = languagesFileURL,
              let data = try? Data(contentsOf: url),
              let languages = try? JSONDecoder().decode([DeepLLanguage].self, from: data) else {
            return []
        }

        return languages
    }

    private static var languagesFileURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("languages.json")
    }
}

struct DeepLLanguagePair: Equatable {
    let first: DeepLLanguage
    let second: DeepLLanguage

    init(
        languages: [DeepLLanguage],
        firstCode: String,
        secondCode: String
    ) throws {
        guard let first = languages.first(where: { $0.language == firstCode }),
              let second = languages.first(where: { $0.language == secondCode }) else {
            throw DeepLManagerError.missingRequiredLanguages
        }

        self.first = first
        self.second = second
    }
}
