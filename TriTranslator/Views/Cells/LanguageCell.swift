//
//  LanguageCell.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/22/25.
//

import SwiftUI

struct LanguageCell: View {
    var language: DeepLLanguage
    
    var body: some View {
        Text("\(language.name)")
            .background {
                Color.green.opacity(0.2)
            }
    }
}

#Preview {
    var languages: [DeepLLanguage] = [
        .init(language: "EN", name: "English"),
        .init(language: "ES", name: "Español"),
        .init(language: "IT", name: "Italian"),
        .init(language: "FR", name: "French"),
        .init(language: "CH", name: "Chinesse"),
        .init(language: "EN", name: "English"),
        .init(language: "ES", name: "Español"),
        .init(language: "IT", name: "Italian"),
        .init(language: "FR", name: "French"),
        .init(language: "CH", name: "Chinesse")
    ].shuffled()
    
    VStack {
        LazyVGrid(columns: [GridItem(.flexible(minimum: 0, maximum: 20))]) {
            ForEach(languages) { language in
                LanguageCell(language: language)
            }
        }
    }
}
