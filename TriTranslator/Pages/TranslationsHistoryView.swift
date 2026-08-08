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
    @State private var loadRequestID: UUID?
    @State private var retryTask: Task<Void, Never>?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading translations…")
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("Couldn’t Load Translations", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Try Again", systemImage: "arrow.clockwise") {
                        retryLoadingTranslations()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if firestoreManager.translations.isEmpty,
                      firestoreManager.skippedTranslationCount > 0 {
                ContentUnavailableView {
                    Label("Saved Translations Unavailable", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("The saved records could not be read.")
                } actions: {
                    Button("Try Again", systemImage: "arrow.clockwise") {
                        retryLoadingTranslations()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if firestoreManager.translations.isEmpty {
                ContentUnavailableView(
                    "No Translations",
                    systemImage: "text.bubble",
                    description: Text("Your translation history will appear here.")
                )
            } else {
                ScrollView {
                    LazyVStack {
                        if firestoreManager.skippedTranslationCount > 0 {
                            Label(
                                "Some saved translations could not be read.",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .padding(.horizontal)
                        }

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
        .onDisappear {
            retryTask?.cancel()
            retryTask = nil
            loadRequestID = nil
            isLoading = false
        }
    }

    @MainActor
    private func loadTranslations() async {
        guard !Task.isCancelled,
              loadRequestID == nil else {
            return
        }

        let requestID = UUID()
        loadRequestID = requestID
        isLoading = true
        errorMessage = nil
        defer {
            if loadRequestID == requestID {
                isLoading = false
                loadRequestID = nil
                retryTask = nil
            }
        }

        do {
            try await firestoreManager.getTranslations()
        } catch is CancellationError {
            return
        } catch {
            guard loadRequestID == requestID else {
                return
            }

            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func retryLoadingTranslations() {
        guard retryTask == nil,
              loadRequestID == nil else {
            return
        }

        retryTask = Task {
            await loadTranslations()
        }
    }
}
