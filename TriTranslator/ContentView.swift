//
//  ContentView.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/19/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State var email: String = ""
    @State var password: String = ""

    var body: some View {
        VStack {
            Text("Signed In: \(authViewModel.isSignedIn ? "🟢" : "🔴")")
            
            if authViewModel.isSignedIn {
                Text("Hello, welcome")
                Text("Now you can see my secrets!")
            } else {
                
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                TextField("Password", text: $password)
                    .textContentType(.password)
                
                Button("Sign In") {
                    Task {
                        do {
                            print("signing in")
                            try await authViewModel.signIn(email: email, password: password)
                            print("signed in")
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                
                Button("Sign Up") {
                    Task {
                        do {
                            print("signing up")
                            try await authViewModel.signUp(email: email, password: password)
                            print("signed up")
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
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
        
    }
}

//#Preview {
//    ContentView()
//}
