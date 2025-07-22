//
//  ContentView.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/19/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var showLoginPage: Bool = false
    
    @State private var firestoreManager: FirestoreManager = .init()
    
    @State private var sourceText: String = ""
    @State private var translatedText: String = ""
    
    @StateObject private var dLManager: DeepLManager = .init()
    
    @State private var languages: [DeepLLanguage] = []
    
    @State private var selectedLanguage: DeepLLanguage = DeepLLanguage(language: "", name: "")
    
    var body: some View {
        VStack {
            Text("Signed In: \(authViewModel.isSignedIn ? "🟢" : "🔴")")
            
            if authViewModel.isSignedIn {
                HStack {
                    Button("Translate") {
                        Task {
                            do {
                                // create the Translation object (perform the actual translation)
                                let translation = try await dLManager.translate(sourceText: sourceText, targetLang: selectedLanguage.language)!
                                // get the translation response and update the @State value (UI)
                                translatedText = translation.responseTranslation!.translations[0].text
                                // upload the Translation to Firestore
                                firestoreManager.addTranslation(translation)
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                    }
                }
                .padding()
                
                TextField("Texto para traducir", text: $sourceText)
                TextField("Translated text", text: $translatedText)
                
                LanguagesView(languages: $languages, selectedLang: $selectedLanguage)
                
//                ScrollView {
//                    VStack {
//                        ForEach(firestoreManager.translations) { translation in
//                            TranslationCell(translation: translation)
//                        }
//                    }
//                }
            }
            
            Button("Sign out") {
                Task {
                    do {
                        print("signing out")
                        try authViewModel.signOut()
                        print("signed out")
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            .disabled(!authViewModel.isSignedIn)
        }
        .padding()
        .task {
            do {
                try await firestoreManager.getTranslations()
//                try await dLManager.getLanguages()
            } catch {
                print(error.localizedDescription)
            }
        }
        .onAppear {
            showLoginPage = !authViewModel.isSignedIn
            if languages.count == 0 {
//                languages = dLManager.languages
                languages = DeepLLanguage.loadLanguages()
            }
        }
        .onChange(of: authViewModel.isSignedIn) { _ , newValue in
            showLoginPage = !newValue
        }
        .sheet(isPresented: $showLoginPage) {
            LoginPage()
        }
    }
}

