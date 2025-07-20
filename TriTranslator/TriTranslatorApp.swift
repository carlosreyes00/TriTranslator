//
//  TriTranslatorApp.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/19/25.
//

import SwiftUI
import FirebaseCore

@main
struct TriTranslatorApp: App {
    
    @State private var authViewModel: AuthViewModel?
    
    init() {
        FirebaseApp.configure()
        authViewModel = AuthViewModel()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel!)
        }
    }
}
