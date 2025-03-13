//
//  LoginView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-19.
//

import SFSafeSymbols
import SwiftUI
import AuthenticationServices
import AppUI
import TelemetryDeck

private extension Double {
  static let animationSpeed: Double = 1.5
}

struct LoginView: View {
  let showDismissButton: Bool
  let onFinish: () -> Void

  init(
    showDismissButton: Bool = true,
    onFinish: @escaping () -> Void
  ) {
    self.showDismissButton = showDismissButton
    self.onFinish = onFinish
  }

  @Environment(\.dismiss) var dismiss

  @State private var viewModel = ViewModel()

  @State private var authorizationState: String?
  @State private var error: Error?

  var body: some View {
    ZStack {
      BloomPlusPaywallHeroImageView()
        .zStackAlignment(.top)
        .clipped()
        .ignoresSafeArea(edges: .top)


      VStack {
        ScrollView {
          VStack {
            DisplayAppIcon()
              .frame(width: 80)

            Text("Welcome to Bloom")
              .font(.title)
              .fontDesign(.rounded)
              .bold()

            BloomPlusFeaturesListView()
              .padding(.bottom)

            HStack {
              Link("Privacy Policy", destination: .privacyPolicy)
                .frame(height: 44)

              Text("•")

              Link("Terms of Service", destination: .termsOfService)
                .frame(height: 44)
            }
            .foregroundStyle(.tint)
          }
          .padding(.top)
        }

      }
      .shelf {
        SignInWithAppleButton(
          onRequest: { (request) in
            authorizationState = UUID().uuidString
            request.state = authorizationState
            request.requestedScopes = [.fullName, .email]
          },
          onCompletion: handleSignInResult
        )
        .signInWithAppleButtonStyle(.black)
        .frame(height: 60)
        .frame(maxWidth: 400)
        .clipShape(RoundedRectangle(cornerRadius: 17))
      }
      .groupedBackground()
      .padding(.top, 170)
    }
    .overlay {
      if showDismissButton {
        dismissButton
          .padding()
          .zStackAlignment(.topLeading)
      }
    }
    .groupedBackground()
    .alert(error: $error)
    .presentationCompactAdaptation(.fullScreenCover)
  }
}

private extension LoginView {

  var dismissButton: some View {
    Button {
      dismiss()
      onFinish()
    } label: {
      Image(systemSymbol: .xmarkCircleFill)
        .foregroundStyle(.text.secondary, .fill)
        .font(.largeTitle)
    }
    .frame(square: 44)
  }

  func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
    switch result {
    case .success(let authorization):
      switch authorization.credential {
      case let credential as ASAuthorizationAppleIDCredential:
        guard credential.state == authorizationState else {
          // Something fishy is going on... Just give them a generic error.
          self.error = NSError(description: "There was a problem loging in. Please try again later.")
          return
        }

        Task {
          do {
            try await viewModel.authenticate(using: credential)
            await MainActor.run {
              dismiss()
              onFinish()
            }
          } catch {
            TelemetryDeck.errorOccurred(
              id: "LoginView.authenticate",
              category: .thrownException,
              message: error.localizedDescription
            )
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
  LoginView {

  }
}
