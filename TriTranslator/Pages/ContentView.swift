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
    @State private var translatedText1: String = ""
    @State private var translatedText2: String = ""
    
    @StateObject private var dLManager: DeepLManager = .init()
    
    // I set these vars to "nil" so I dont have to deal with unwrapping during development phase
    @State private var selectedLanguage1: DeepLLanguage = DeepLLanguage(language: "nil", name: "nil")
    @State private var selectedLanguage2: DeepLLanguage = DeepLLanguage(language: "nil", name: "nil")
    
    var body: some View {
        VStack {
            Text("Signed In: \(authViewModel.isSignedIn ? "🟢" : "🔴")")
            
            if authViewModel.isSignedIn {
                HStack {
                    Button("Translate") {
                        Task {
                            do {
                                // create the Translation objects (perform the actual translations)
                                async let translation1 = dLManager.translate(sourceText: sourceText, targetLang: selectedLanguage1.language)!
                                async let translation2 = dLManager.translate(sourceText: sourceText, targetLang: selectedLanguage2.language)!
                                // get the translation response and update the @State value (UI)
                                translatedText1 = try await translation1.responseTranslation!.translations[0].text
                                translatedText2 = try await translation2.responseTranslation!.translations[0].text
                                // upload the Translation to Firestore
//                                firestoreManager.addTranslation(translation1)
//                                firestoreManager.addTranslation(translation2)
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                    }
                }
                .padding()
                
                TextField("Texto para traducir", text: $sourceText)
                TextField("Translated text to \(selectedLanguage1.name)", text: $translatedText1)
                TextField("Translated text to \(selectedLanguage2.name)", text: $translatedText2)
                
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
            
            HStack {
                LanguagesView(selectedLang: $selectedLanguage1)
                LanguagesView(selectedLang: $selectedLanguage2)
            }
        }
        .padding()
        .task {
            do {
                try await firestoreManager.getTranslations()
            } catch {
                print(error.localizedDescription)
            }
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
    }
}

