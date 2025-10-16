//
//  LanguagesView.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/22/25.
//

import SwiftUI

struct LanguagesView: View {
    @Binding var selectedLang: DeepLLanguage
    
    @State private var languages: [DeepLLanguage] = []
    
    var body: some View {
        VStack {
            Picker("languages", selection: $selectedLang) {
                ForEach(languages, id: \.id) { language in
                    Text("\(language.name)").tag(language)
                }
            }
            .pickerStyle(.wheel)
        }
        .task {
            do {
                let languagesArray = try await DeepLManager().getLanguages()
                        
                languagesArray.forEach { lang in
                    languages.append(lang)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
