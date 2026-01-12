//
//  AuthViewModel.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/19/25.
//

import SwiftUI
@preconcurrency import FirebaseAuth

@preconcurrency
class AuthViewModel: ObservableObject {
    @Published var user: User? = nil
    @Published var isSignedIn: Bool = false
    
    init() {
        self.user = Auth.auth().currentUser
        self.isSignedIn = user != nil
    }
    
    func signUp(email: String, password: String) async throws {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        
        DispatchQueue.main.async { [self] in
            user = authDataResult.user
            isSignedIn = true
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
        
        DispatchQueue.main.async { [self] in
            user = authDataResult.user
            isSignedIn = true
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        
        self.user = nil
        self.isSignedIn = false
    }
}
