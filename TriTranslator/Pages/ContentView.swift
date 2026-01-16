//
//  ContentView.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/19/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var firestoreManager: FirestoreManager
    
    @State private var showLoginPage = false
    @State private var showHistoryView = false
    
    @State private var sourceText = ""
    @State private var translatedText1 = ""
    @State private var translatedText2 = ""
    
    private var dLManager: DeepLManager = .init()
    
    @State private var selectedLanguage1 = DeepLLanguage(language: "EN-US", name: "English (American)")
    @State private var selectedLanguage2 = DeepLLanguage(language: "FR", name: "French")
    
    var body: some View {
        NavigationStack {
            VStack {
                if authViewModel.isSignedIn {
                    VStack {
                        HStack {
                            CustomTextField(
                                text: $sourceText,
                                placeholder: "Text to translate"
                            )
                        }
                        HStack {
                            CustomTextField(
                                text: $translatedText1,
                                placeholder: "Translated text to \(selectedLanguage1.name)"
                            )
                            LanguagesView(
                                selectedLang: $selectedLanguage1,
                                firstLanguage: "EN-US"
                            )
                            .frame(width: 70)
                        }
                        HStack {
                            CustomTextField(
                                text: $translatedText2,
                                placeholder: "Translated text to \(selectedLanguage2.name)"
                            )
                            LanguagesView(
                                selectedLang: $selectedLanguage2,
                                firstLanguage: "FR"
                            )
                            .frame(width: 70)
                        }
                        Button("Translate") {
                            Task {
                                do {
                                    // create the Translation objects (perform the actual translations)
                                    async let translation1 = dLManager.translate(
                                        sourceText: sourceText,
                                        targetLang: selectedLanguage1.language
                                    )!
                                    async let translation2 = dLManager.translate(
                                        sourceText: sourceText,
                                        targetLang: selectedLanguage2.language
                                    )!
                                    // get the translation response and update the @State value (UI)
                                    translatedText1 = try await translation1.responseTranslation!
                                        .translations[0].text
                                    translatedText2 = try await translation2.responseTranslation!
                                        .translations[0].text
                                    // upload the Translation to Firestore
                                    try await firestoreManager.addTranslation(translation1)
                                    try await firestoreManager.addTranslation(translation2)
                                } catch {
                                    print(error.localizedDescription)
                                }
                            }
                        }
                        .buttonStyle(.glassProminent)
                        .padding(.top)
                    }
                    .padding(.horizontal)
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
                    Button("Sign out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                        do {
                            try authViewModel.signOut()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                .disabled(!authViewModel.isSignedIn)
            }
            .onAppear {
                showLoginPage = !authViewModel.isSignedIn
            }
            .onChange(of: authViewModel.isSignedIn) { _ , newValue in
                showLoginPage = !newValue
            }
            .sheet(isPresented: $showLoginPage) {
                LoginPage()
            }
            .sheet(isPresented: $showHistoryView) {
                TranslationsHistoryView()
          }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(FirestoreManager())
}
