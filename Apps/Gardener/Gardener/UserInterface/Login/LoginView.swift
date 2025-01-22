//
//  LoginView.swift
//  Gardener
//
//  Created by Mark DiFranco on 2025-01-22.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {

  @Environment(\.dismiss) var dismiss

  @State private var viewModel = ViewModel()

  @State private var authorizationState: String?
  @State private var error: Error?

  var body: some View {
    VStack {
      Spacer()

      Image(.displayAppIcon)
        .resizable()
        .frame(square: 120)

      Text("Gardener")
        .font(.largeTitle)
        .fontDesign(.rounded)
        .bold()

      Text("Admin Tool")
        .font(.title3)
        .fontDesign(.rounded)
        .bold()

      Spacer()

      signInWithAppleButton
    }
    .frame(square: 500)
    .interactiveDismissDisabled()
  }
}

private extension LoginView {

  var signInWithAppleButton: some View {
    SignInWithAppleButton(
      onRequest: { (request) in
        authorizationState = UUID().uuidString
        request.state = authorizationState
        request.requestedScopes = [.fullName, .email]
      },
      onCompletion: handleSignInResult
    )
    .signInWithAppleButtonStyle(.black)
    .frame(height: 80)
    .frame(width: 200)
    .padding(.horizontal)
  }
}

private extension LoginView {

  func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
    switch result {
    case .success(let authorization):
      switch authorization.credential {
      case let credential as ASAuthorizationAppleIDCredential:
        guard credential.state == authorizationState else {
          // TODO: Something fishy is going on
          print("Invalid state returned: \(credential.state ?? ""), expected \(authorizationState ?? "")")
          return
        }

        switch credential.realUserStatus {
        case .unknown:
          print("Unknown user status, something fishy might be going on.")
        default:
          break
        }

        Task {
          do {
            try await viewModel.authenticate(using: credential)
            await MainActor.run {
              dismiss()
            }
          } catch {
            self.error = error
          }
        }
      default:
        break
      }
    case .failure(let error):
      if let authError = error as? ASAuthorizationError {
        switch authError.code {
        case .canceled:
          return // Do nothing when the user cancels
        default:
          break
        }
      }
      self.error = error
    }
  }
}

#Preview {
  LoginView()
}
