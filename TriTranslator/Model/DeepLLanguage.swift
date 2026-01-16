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
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("languages.json")
        
        do {
            let data = try JSONEncoder().encode(languages)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Error saving local languages: \(error.localizedDescription)")
        }
    }
    
    static func loadLanguagesFromDisk() -> [DeepLLanguage] {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("languages.json")
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([DeepLLanguage].self, from: data)
        } catch {
            print("Error loading local languages: \(error.localizedDescription)")
            return []
        }
    }
}

