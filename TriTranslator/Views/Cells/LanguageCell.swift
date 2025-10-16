//
//  LanguageCell.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/22/25.
//

import SwiftUI

struct LanguageCell: View {
    var language: DeepLLanguage
    @Binding var selectedLang: DeepLLanguage
    
    var body: some View {
        Text(language.name)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(language == selectedLang ? Color.indigo.opacity(0.2) : Color.clear)
            }
            .fixedSize()
    }
}
