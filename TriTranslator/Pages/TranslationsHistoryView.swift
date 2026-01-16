//
//  TranslationsHistoryView.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 1/15/26.
//

import SwiftUI

struct TranslationsHistoryView: View {
    @EnvironmentObject private var firestoreManager: FirestoreManager
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(firestoreManager.translations) { translation in
                    TranslationCell(translation: translation)
                        .padding(.vertical)
                }
            }
        }
        .navigationTitle("Translations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

//#Preview {
//    NavigationStack {
//        TranslationsHistoryView()
//            .environmentObject(FirestoreManager())
//    }
//}
