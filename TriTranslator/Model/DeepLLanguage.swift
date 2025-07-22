//
//  DeepLLanguage.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/22/25.
//

import Foundation

struct DeepLLanguage: Codable, Identifiable, Equatable {
    let id = UUID()
    
    let language: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case language = "language"
        case name = "name"
    }

    static func saveLanguages(languages: [DeepLLanguage]) {
        print("saving languages")
        
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("languages.json")
        let data = try! JSONEncoder().encode(languages)
        try! data.write(to: url, options: .atomic)
        print("languages were saved succesfully")
        print(data)
    }
    
    static func loadLanguages() -> [DeepLLanguage] {
        print("loading languages")
        
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("languages.json")
        let data = try! Data(contentsOf: url)
        do {
            return try JSONDecoder().decode([DeepLLanguage].self, from: data)
        } catch {
            print("error returning the array")
            return []
        }
    }
}

