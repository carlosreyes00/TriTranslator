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
    
    var body: some View {
        VStack {
            Text("Signed In: \(authViewModel.isSignedIn ? "🟢" : "🔴")")
            
            if authViewModel.isSignedIn {
                Text("Hello, welcome")
                Text("Now you can see my secrets!")
                
                HStack {
                    Button("Add Translation") {
                        firestoreManager
                            .addTranslation(
                                sourceText: sourceText,
                                translatedText: "this is the text translated \(Int.random(in: 1...100))",
                                sourceLang: "EN",
                                targetLang: "ES",
                                createdAt: Date.now
                            )
                    }
                }
                
                TextField("Text to translate", text: $sourceText)
                
//                List(firestoreManager.translations) { translation in
//                    VStack {
//                        Text("\(translation.createdAt)")
//                            .bold()
//                        Text("from: \(translation.sourceText)")
//                        Text("to: \(translation.translatedText)")
//                            .font(.footnote)
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

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
