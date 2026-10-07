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
                VStack(alignment: .leading, spacing: 5) {
                    textRow(language: translation.sourceLanguage, text: translation.sourceText)
                    Divider()
                    ForEach(translation.translations.indices, id: \.self) { index in
                        let result = translation.translations[index]
                        textRow(language: result.targetLanguage, text: result.text)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Gradient(colors: [.blue, .indigo]), lineWidth: 2)
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
        
        TranslationCell(
            translation: .init(
                sourceText: "Hola, mi nombre es iPhone, cuál es tu nombre?, Hola, mi nombre es iPhone, cuál es tu nombre?, Hola, mi nombre es iPhone, cuál es tu nombre?",
                sourceLanguage: "ES",
                translations: [
                    .init(targetLanguage: "EN-US", text: "Hi, my name is iPhone, what's your name?,Hi, my name is iPhone, what's your name?,Hi, my name is iPhone, what's your name?"),
                    .init(targetLanguage: "FR", text: "Bonjour, je m’appelle iPhone")
                ],
                createdAt: .now.addingTimeInterval(-300)
            )
        )
        
        TranslationCell(
            translation: .init(
                sourceText: "Hola, mi nombre es iPhone",
                sourceLanguage: "ES",
                translations: [
                    .init(targetLanguage: "EN-US", text: "Hi, my name is iPhone"),
                    .init(targetLanguage: "FR", text: "Bonjour, je m’appelle iPhone")
                ],
                createdAt: .now.addingTimeInterval(-720)
            )
        )
    }
}
