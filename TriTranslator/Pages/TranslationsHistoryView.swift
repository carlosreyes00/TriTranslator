//
//  TranslationsHistoryView.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 1/15/26.
//

import SwiftUI

struct TranslationsHistoryView: View {
    @EnvironmentObject private var firestoreManager: FirestoreManager

    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading translations…")
            } else if let errorMessage {
                ContentUnavailableView(
                    "Couldn’t Load Translations",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else if firestoreManager.translations.isEmpty {
                ContentUnavailableView(
                    "No Translations",
                    systemImage: "text.bubble",
                    description: Text("Your translation history will appear here.")
                )
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(firestoreManager.translations) { translation in
                            TranslationCell(translation: translation)
                                .padding(.vertical)
                        }
                    }
                }
            }
        }
        .navigationTitle("Translations")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTranslations()
        }
    }

    @MainActor
    private func loadTranslations() async {
        isLoading = true
        errorMessage = nil

        do {
            try await firestoreManager.getTranslations()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

//#Preview {
//    NavigationStack {
//        TranslationsHistoryView()
//            .environmentObject(FirestoreManager())
//    }
//}
