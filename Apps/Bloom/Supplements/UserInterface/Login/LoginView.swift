//
//  LoginView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-19.
//

import SwiftUI
import AuthenticationServices
import AppUI

struct LoginView: View {
  @Environment(\.colorScheme) var colorScheme

  @State private var authorizationState: String?
  @State private var error: Error?

  @State private var viewModel = ViewModel()

  var body: some View {
    VStack {

      Spacer()

      SignInWithAppleButton(
        onRequest: { (request) in
          authorizationState = UUID().uuidString
          request.state = authorizationState
        },
        onCompletion: handleSignInResult)
      .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
      .frame(height: 60)
      .frame(maxWidth: 400)
      .padding(.horizontal)
    }
    .padding()
    .alert(error: $error)
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

        do {
          try viewModel.authenticate(using: credential)
        } catch {
          self.error = error
        }
      default:
        break
      }
    case .failure(let error):
      self.error = error
    }
  }
}

#Preview {
  LoginView()
}
