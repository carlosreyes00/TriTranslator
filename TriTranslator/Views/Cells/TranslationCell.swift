//
//  TranslationCell.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/21/25.
//

import SwiftUI

struct TranslationCell: View {
    var translation: Translation

    var body: some View {
        VStack(alignment: .trailing) {
            if translation.hasDisplayContent {
                VStack(alignment: .leading, spacing: 12) {
                    textRow(language: translation.sourceLanguage, text: translation.sourceText)
                    Divider()
                    ForEach(translation.translations.indices, id: \.self) { index in
                        let result = translation.translations[index]
                        textRow(language: result.targetLanguage, text: result.text)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.indigo, lineWidth: 1)
                }
            } else {
                ContentUnavailableView(
                    "Saved Translation Unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This history record is incomplete.")
                )
                .padding()
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.orange, lineWidth: 1)
                }
            }
            Text(translation.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
        }
        .padding(.horizontal)
    }

    private func textRow(language: String, text: String) -> some View {
        HStack(alignment: .top) {
            Text("\(language):")
                .bold()
                .fixedSize()
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ScrollView {
        TranslationCell(
            translation: .init(
                sourceText: "Hola, mi nombre es iPhone",
                sourceLanguage: "ES",
                translations: [
                    .init(targetLanguage: "EN-US", text: "Hi, my name is iPhone"),
                    .init(targetLanguage: "FR", text: "Bonjour, je m’appelle iPhone")
                ],
                createdAt: .now
            )
        )
    }
}
