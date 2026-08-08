//
//  LanguagesView.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/22/25.
//

import SwiftUI

struct LanguagesView: View {
    let languages: [DeepLLanguage]
    @Binding var selectedLang: DeepLLanguage
    let isLoading: Bool
    let isDisabled: Bool

    var body: some View {
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
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text(selectedLang.language)
            }
        }
        .menuOrder(.fixed)
        .disabled(isDisabled || isLoading || languages.isEmpty)
    }
}
