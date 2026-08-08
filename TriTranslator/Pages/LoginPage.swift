//
//  LoginPage.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/20/25.
//

import SwiftUI

struct LoginPage: View {
    private enum AuthenticationAction: Equatable {
        case signIn
        case signUp

        var buttonTitle: String {
            switch self {
            case .signIn: "Sign In"
            case .signUp: "Sign Up"
            }
        }
    }

    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var actionInProgress: AuthenticationAction?
    @State private var authenticationErrorMessage: String?

    private var hasInvalidPasswordLength: Bool {
        !password.isEmpty && password.count < 6
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && password.count >= 6
            && actionInProgress == nil
    }

    var body: some View {
        VStack(spacing: 16) {
            Section {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(actionInProgress != nil)
                    .onChange(of: email) { _, _ in
                        authenticationErrorMessage = nil
                    }

                VStack(alignment: .leading) {
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .disabled(actionInProgress != nil)
                        .onChange(of: password) { _, _ in
                            authenticationErrorMessage = nil
                        }

                    if hasInvalidPasswordLength {
                        Text("Your password should be at least 6 characters long")
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .padding(.horizontal)

            HStack {
                authenticationButton(for: .signIn)
                authenticationButton(for: .signUp)
            }
            .buttonStyle(.borderedProminent)

            if let authenticationErrorMessage {
                Label(authenticationErrorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .accessibilityIdentifier("authenticationError")
            }
        }
        .interactiveDismissDisabled()
    }

    private func authenticationButton(for action: AuthenticationAction) -> some View {
        Button {
            startAuthentication(using: action)
        } label: {
            HStack(spacing: 8) {
                if actionInProgress == action {
                    ProgressView()
                }
                Text(action.buttonTitle)
            }
        }
        .disabled(!canSubmit)
    }

    @MainActor
    private func startAuthentication(using action: AuthenticationAction) {
        guard actionInProgress == nil else {
            return
        }

        actionInProgress = action
        authenticationErrorMessage = nil

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let submittedPassword = password

        Task {
            await authenticate(
                using: action,
                email: normalizedEmail,
                password: submittedPassword
            )
        }
    }

    @MainActor
    private func authenticate(
        using action: AuthenticationAction,
        email: String,
        password: String
    ) async {
        defer { actionInProgress = nil }

        do {
            switch action {
            case .signIn:
                try await authViewModel.signIn(email: email, password: password)
            case .signUp:
                try await authViewModel.signUp(email: email, password: password)
            }
        } catch is CancellationError {
            return
        } catch {
            authenticationErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginPage()
        .environmentObject(AuthViewModel(previewIsSignedIn: false))
}
