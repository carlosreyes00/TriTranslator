//
//  ContentView.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/19/25.
//

import SwiftUI

struct ContentView: View {
    private struct AccountAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var firestoreManager: FirestoreManager

    @State private var showLoginPage = false

    @State private var sourceText = ""
    @State private var translatedText1 = ""
    @State private var translatedText2 = ""

    @State private var languages = [DeepLLanguage]()
    @State private var isLoadingLanguages = false
    @State private var languageErrorMessage: String?
    @State private var languageRequestID: UUID?
    @State private var languageRetryTask: Task<Void, Never>?

    @State private var isTranslating = false
    @State private var translationErrorMessage: String?
    @State private var persistenceErrorMessage: String?
    @State private var translationTask: Task<Void, Never>?
    @State private var translationRequestID: UUID?
    @State private var accountAlert: AccountAlert?

    @State private var selectedLanguage1 = DeepLLanguage(language: "EN-US", name: "English (American)")
    @State private var selectedLanguage2 = DeepLLanguage(language: "FR", name: "French")

    private let deepLManager: DeepLManager

    init(deepLManager: DeepLManager = DeepLManager()) {
        self.deepLManager = deepLManager
    }

    private var canTranslate: Bool {
        authViewModel.isSignedIn
            && !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !languages.isEmpty
            && languageErrorMessage == nil
            && !isLoadingLanguages
            && !isTranslating
    }

    var body: some View {
        NavigationStack {
            VStack {
                if authViewModel.isSignedIn {
                    VStack(spacing: 12) {
                        CustomTextField(
                            text: $sourceText,
                            placeholder: "Text to translate"
                        )
                        .disabled(isTranslating)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Hide Keyboard", systemImage: "keyboard.chevron.compact.down") {
                                    UIApplication.shared.sendAction(
                                        #selector(UIResponder.resignFirstResponder),
                                        to: nil,
                                        from: nil,
                                        for: nil
                                    )
                                }
                            }
                        }

                        HStack {
                            CustomTextField(
                                text: $translatedText1,
                                placeholder: "Translated text to \(selectedLanguage1.name)"
                            )
                            .disabled(isTranslating)

                            LanguagesView(
                                languages: languages,
                                selectedLang: $selectedLanguage1,
                                isLoading: isLoadingLanguages,
                                isDisabled: isTranslating
                            )
                            .frame(width: 70)
                        }

                        HStack {
                            CustomTextField(
                                text: $translatedText2,
                                placeholder: "Translated text to \(selectedLanguage2.name)"
                            )
                            .disabled(isTranslating)

                            LanguagesView(
                                languages: languages,
                                selectedLang: $selectedLanguage2,
                                isLoading: isLoadingLanguages,
                                isDisabled: isTranslating
                            )
                            .frame(width: 70)
                        }

                        if let languageErrorMessage {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(languageErrorMessage, systemImage: "exclamationmark.triangle.fill")
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                                    .accessibilityIdentifier("languageError")

                                Button("Retry Loading Languages", systemImage: "arrow.clockwise") {
                                    retryLoadingLanguages()
                                }
                                .buttonStyle(.bordered)
                                .disabled(isLoadingLanguages)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            startTranslation()
                        } label: {
                            HStack(spacing: 8) {
                                if isTranslating {
                                    ProgressView()
                                }
                                Text(isTranslating ? "Translating…" : "Translate")
                            }
                        }
                        .buttonStyle(.glassProminent)
                        .padding(.top)
                        .disabled(!canTranslate)
                        .accessibilityIdentifier("translateButton")

                        if let translationErrorMessage {
                            Label(translationErrorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityIdentifier("translationError")
                        }

                        if let persistenceErrorMessage {
                            Label(persistenceErrorMessage, systemImage: "exclamationmark.icloud.fill")
                                .font(.footnote)
                                .foregroundStyle(.orange)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityIdentifier("persistenceError")
                        }
                    }
                    .padding(.horizontal)
                    .task {
                        if languages.isEmpty {
                            await loadLanguages()
                        }
                    }
                    .onChange(of: sourceText) { _, _ in
                        guard !isTranslating else {
                            return
                        }

                        translatedText1 = ""
                        translatedText2 = ""
                        translationErrorMessage = nil
                        persistenceErrorMessage = nil
                    }
                    .onChange(of: selectedLanguage1) { _, _ in
                        guard !isTranslating else {
                            return
                        }

                        translatedText1 = ""
                        translationErrorMessage = nil
                        persistenceErrorMessage = nil
                    }
                    .onChange(of: selectedLanguage2) { _, _ in
                        guard !isTranslating else {
                            return
                        }

                        translatedText2 = ""
                        translationErrorMessage = nil
                        persistenceErrorMessage = nil
                    }
                }
            }
            .navigationTitle("Tri-Translator")
            .toolbar {
                Menu("Options", systemImage: "ellipsis") {
                    NavigationLink {
                        TranslationsHistoryView()
                            .environmentObject(firestoreManager)
                    } label: {
                        Label("History", systemImage: "list.bullet")
                    }

                    Button(
                        "Sign out",
                        systemImage: "rectangle.portrait.and.arrow.right",
                        role: .destructive,
                        action: signOut
                    )
                }
                .disabled(!authViewModel.isSignedIn)
            }
            .onAppear {
                showLoginPage = !authViewModel.isSignedIn
            }
            .onChange(of: authViewModel.isSignedIn) { _, isSignedIn in
                showLoginPage = !isSignedIn
                if !isSignedIn {
                    cancelLanguageLoading()
                    cancelTranslation()
                }
            }
            .onDisappear {
                cancelLanguageLoading()
                cancelTranslation()
            }
            .sheet(isPresented: $showLoginPage) {
                LoginPage()
            }
            .alert(item: $accountAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    @MainActor
    private func loadLanguages(forceRefresh: Bool = false) async {
        guard !Task.isCancelled,
              authViewModel.isSignedIn,
              !isLoadingLanguages else {
            return
        }

        let requestID = UUID()
        isLoadingLanguages = true
        languageErrorMessage = nil
        languageRequestID = requestID
        defer { finishLanguageRequest(requestID) }

        do {
            let loadedLanguages = try await deepLManager.getLanguages(forceRefresh: forceRefresh)
            try Task.checkCancellation()

            let defaultLanguages = try DeepLLanguagePair(
                languages: loadedLanguages,
                firstCode: "EN-US",
                secondCode: "FR"
            )

            guard languageRequestID == requestID,
                  authViewModel.isSignedIn else {
                return
            }

            languages = loadedLanguages
            selectedLanguage1 = defaultLanguages.first
            selectedLanguage2 = defaultLanguages.second
        } catch is CancellationError {
            return
        } catch {
            guard languageRequestID == requestID else {
                return
            }

            languages = []
            languageErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func finishLanguageRequest(_ requestID: UUID) {
        guard languageRequestID == requestID else {
            return
        }

        isLoadingLanguages = false
        languageRequestID = nil
        languageRetryTask = nil
    }

    @MainActor
    private func cancelLanguageLoading() {
        languageRetryTask?.cancel()
        languageRetryTask = nil
        languageRequestID = nil
        isLoadingLanguages = false
    }

    @MainActor
    private func retryLoadingLanguages() {
        guard !isLoadingLanguages,
              languageRetryTask == nil else {
            return
        }

        languageRetryTask?.cancel()
        languageRetryTask = Task {
            await loadLanguages(forceRefresh: true)
        }
    }

    @MainActor
    private func startTranslation() {
        guard canTranslate else {
            return
        }

        let requestID = UUID()
        let requestedText = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        let requestedLanguage1 = selectedLanguage1.language
        let requestedLanguage2 = selectedLanguage2.language

        translationErrorMessage = nil
        persistenceErrorMessage = nil
        translatedText1 = ""
        translatedText2 = ""
        isTranslating = true
        translationRequestID = requestID

        translationTask = Task {
            await performTranslation(
                sourceText: requestedText,
                targetLanguage1: requestedLanguage1,
                targetLanguage2: requestedLanguage2,
                requestID: requestID
            )
        }
    }

    @MainActor
    private func performTranslation(
        sourceText: String,
        targetLanguage1: String,
        targetLanguage2: String,
        requestID: UUID
    ) async {
        defer { finishTranslationRequest(requestID) }

        do {
            try Task.checkCancellation()

            async let translation1 = deepLManager.translate(
                sourceText: sourceText,
                targetLang: targetLanguage1
            )
            async let translation2 = deepLManager.translate(
                sourceText: sourceText,
                targetLang: targetLanguage2
            )

            let (resolvedTranslation1, resolvedTranslation2) = try await (translation1, translation2)
            try Task.checkCancellation()

            guard translationRequestID == requestID,
                  authViewModel.isSignedIn else {
                return
            }

            guard let response1 = resolvedTranslation1.responseTranslation?.translations.first,
                  let response2 = resolvedTranslation2.responseTranslation?.translations.first else {
                throw DeepLManagerError.emptyTranslations
            }

            translatedText1 = response1.text
            translatedText2 = response2.text

            do {
                try await firestoreManager.addTranslations([
                    resolvedTranslation1,
                    resolvedTranslation2
                ])
            } catch is CancellationError {
                return
            } catch {
                guard translationRequestID == requestID else {
                    return
                }

                persistenceErrorMessage = "The translations are shown above, but they could not be saved to history. \(error.localizedDescription)"
            }
        } catch is CancellationError {
            return
        } catch {
            guard translationRequestID == requestID else {
                return
            }

            translationErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func finishTranslationRequest(_ requestID: UUID) {
        guard translationRequestID == requestID else {
            return
        }

        isTranslating = false
        translationRequestID = nil
        translationTask = nil
    }

    @MainActor
    private func cancelTranslation() {
        translationTask?.cancel()
        translationTask = nil
        translationRequestID = nil
        isTranslating = false
    }

    @MainActor
    private func signOut() {
        cancelTranslation()

        do {
            try authViewModel.signOut()
            firestoreManager.clearTranslations()
            sourceText = ""
            translatedText1 = ""
            translatedText2 = ""
            translationErrorMessage = nil
            persistenceErrorMessage = nil
        } catch {
            accountAlert = AccountAlert(
                title: "Couldn’t Sign Out",
                message: error.localizedDescription
            )
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel(previewIsSignedIn: false))
        .environmentObject(FirestoreManager())
}
