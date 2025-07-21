//
//  LoginPage.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/20/25.
//

import SwiftUI

struct LoginPage: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var wrongPasswordFormat: Bool = false
    
    var body: some View {
        Section {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
            VStack (alignment: .leading) {
                TextField("Password", text: $password)
                    .textContentType(.password)
                    .onChange(of: password) { _, _ in
                        if password.count > 0 && password.count < 6 {
                            wrongPasswordFormat = true
                        } else {
                            wrongPasswordFormat = false
                        }
                    }
                
                if wrongPasswordFormat {
                    Text("your password should be at least 6 characters long")
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .padding(.horizontal)
        
        HStack {
            Button("Sign In") {
                Task {
                    do {
                        print("signing in")
                        try await authViewModel
                            .signIn(email: email, password: password)
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
                        try await authViewModel
                            .signUp(email: email, password: password)
                        print("signed up")
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    LoginPage()
}
