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
  let onFinish: () -> Void

  @Environment(\.colorScheme) var colorScheme
  @Environment(\.dismiss) var dismiss

  @State private var authorizationState: String?
  @State private var error: Error?

  @State private var viewModel = ViewModel()

  let timer = Timer.publish(every: .animationSpeed, tolerance: 0.1, on: .main, in: .common).autoconnect()
  @State private var backgroundColors: [Color] = [
    .mutedTeal,
    .mutedBlue,
    .mutedIndigo,
    .mutedPink
  ]

  var body: some View {
    VStack {

      Spacer()

      Image(.bloomAppIcon)
        .resizable()
        .frame(square: 160)

      Text("Sign in to log your food")
        .font(.system(size: 30))
        .bold()
        .fontDesign(.rounded)
        .multilineTextAlignment(.center)

      Spacer()

      Group {
        if colorScheme == .light {
          SignInWithAppleButton(
            onRequest: { (request) in
              authorizationState = UUID().uuidString
              request.state = authorizationState
              request.requestedScopes = [.fullName, .email]
            },
            onCompletion: handleSignInResult)
          .signInWithAppleButtonStyle(.white)
        } else {
          SignInWithAppleButton(
            onRequest: { (request) in
              authorizationState = UUID().uuidString
              request.state = authorizationState
              request.requestedScopes = [.fullName, .email]
            },
            onCompletion: handleSignInResult)
          .signInWithAppleButtonStyle(.black)
        }
      }
      .frame(height: 60)
      .frame(maxWidth: 400)
      .padding(.horizontal)
    }
    .overlay {
      dismissButton
        .zStackAlignment(.topLeading)
    }
    .padding()
    .alert(error: $error)
    .background {
      Rectangle()
        .fill(
          LinearGradient(
            colors: backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay {
          Rectangle()
            .fill(.thinMaterial)
        }
        .ignoresSafeArea()
    }
    .animation(.linear(duration: .animationSpeed), value: backgroundColors)
    .presentationCompactAdaptation(.fullScreenCover)
    .onReceive(timer) { _ in
      shiftGradientColors()
    }
  }
}

private extension LoginView {

  var dismissButton: some View {
    Button {
      dismiss()
      onFinish()
    } label: {
      Image(systemSymbol: .xmarkCircleFill)
        .foregroundStyle(.text.secondary, .regularMaterial)
        .font(.largeTitle)
    }
    .frame(square: 44)
  }

  func shiftGradientColors() {
    let last = backgroundColors.removeLast()
    backgroundColors.insert(last, at: 0)
  }

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
