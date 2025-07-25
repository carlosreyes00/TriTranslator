//
//  LanguagesView.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/22/25.
//

import SwiftUI

struct LanguagesView: View {
    @Binding var languages: [DeepLLanguage]
    @Binding var selectedLang: DeepLLanguage
    
    @State private var languageRows: [[DeepLLanguage]] = []
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(languageRows, id: \.self) { row in
                        HStack(spacing: 8) {
                            ForEach(row, id: \.self) { language in
                                LanguageCell(language: language, selectedLang: $selectedLang, geometryWidth: geometry.size.width)
                                    .onTapGesture {
                                        selectedLang = language
                                    }
                            }
                        }
                    }
                }
                .onAppear {
                    calculateRows(for: geometry.size.width)
                }
            }
        }
    }
    
    private func calculateRows(for availableWidth: CGFloat) {
        languageRows = []
        var currentRow: [DeepLLanguage] = []
        var currentRowWidth: CGFloat = 0
        
        for language in languages {
            let languageWidth = language.calculateWidth(usingFont: .systemFont(ofSize: 16)) + 16
            if currentRowWidth + languageWidth <= availableWidth {
                currentRow.append(language)
                currentRowWidth += languageWidth
            } else {
                languageRows.append(currentRow)
                currentRow = [language]
                currentRowWidth = languageWidth
            }
        }
        
        if !currentRow.isEmpty {
            languageRows.append(currentRow)
        }
    }
}

extension DeepLLanguage {
    func calculateWidth(usingFont font: UIFont) -> CGFloat {
        let textWidth = (self.name as NSString).size(withAttributes: [.font: font]).width
        let paddingWidth = 5
        return textWidth + CGFloat(paddingWidth)
    }
}
