//
//  LanguagesView.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/22/25.
//

import SwiftUI

struct LanguagesView: View {
    @State private var languages: [DeepLLanguage] = []
    
    @Binding var selectedLang: DeepLLanguage
    
    let firstLanguage: String
    
    var body: some View {
        HStack {
            Menu {
                ForEach(languages) { lang in
                    Button {
                        selectedLang = lang
                    } label: {
                        HStack {
                            Text(lang.name)
                            if lang == selectedLang {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Text(selectedLang.language)
            }
            .menuOrder(.fixed)
        }
        .task {
            do {
                let languagesArray = try await DeepLManager().getLanguages()
                languages = languagesArray
                selectedLang = languages.first(where: { deepllanguage in
                    deepllanguage.language == firstLanguage
                })!
            } catch {
                print("Failed to load languages: \(error)")
            }
        }
    }
}
