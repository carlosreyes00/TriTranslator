//
//  CustomTextField.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 1/11/26.
//

import SwiftUI

struct CustomTextField: View {
    
    @FocusState private var isFocused: Bool
    @Binding var text: String
    let placeholder: String
    let cornerRadius: CGFloat = 12
    
    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .focused($isFocused)
            .lineLimit(3...6)
            .padding(5)
            .background(content: {
                RoundedRectangle(cornerRadius: cornerRadius).foregroundStyle(Color(.secondarySystemBackground))
            })
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isFocused ? Color.accentColor : Color.black.opacity(0.1), lineWidth: 1)
            )
            .font(.callout)
    }
}

#Preview {
    CustomTextField(text: .constant("source text"), placeholder: "Placeholder here")
}
