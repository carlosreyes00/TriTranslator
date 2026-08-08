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
        VStack (alignment: .trailing) {
            if let content = translation.displayContent {
                VStack (alignment: .leading) {
                    HStack {
                        Text("\(content.sourceLanguage): ")
                            .bold()
                        Text(content.sourceText)
                    }
                    Divider()
                    HStack {
                        Text("\(content.targetLanguage): ")
                            .bold()
                        Text(content.translatedText)
                    }
                }
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
}

#Preview {
    ScrollView {
        VStack {
            TranslationCell(
                translation:
                        .init(
                            requestTranslation:
                                DeepLRequestTranslation(
                                    text: ["Hola, mi nombre es iPhone"],
                                    source_lang: nil,
                                    target_lang: "EN"),
                            responseTranslation: DeepLResponseTranslation(
                                translations: [DeepLResponseTranslation.TranslatedText(
                                    text: "Hi, my name is iPhone, Hi, my name is iPhone",
                                    detected_source_language: "ES"
                                )]
                            ),
                            createdAt: Date.now
                        )
            )
//            ForEach((1..<5)) { _ in
//                TranslationCell(
//                    translation:
//                            .init(
//                                requestTranslation:
//                                    DeepLRequestTranslation(
//                                        text: ["Hola, mi nombre es iPhone"],
//                                        source_lang: nil,
//                                        target_lang: "EN"),
//                                responseTranslation: DeepLResponseTranslation(
//                                    translations: [DeepLResponseTranslation.TranslatedText(
//                                        text: "Hi, my name is iPhone, Hi, my name is iPhone",
//                                        detected_source_language: "ES"
//                                    )]
//                                ),
//                                createdAt: Date.now
//                            )
//                )
//            }
        }
    }
}
