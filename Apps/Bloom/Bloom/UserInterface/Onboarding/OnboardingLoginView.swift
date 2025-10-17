//
//  OnboardingLoginView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-25.
//

import SwiftUI
import SFSafeSymbols
import AuthenticationServices
import AppUI
import TelemetryDeck
import BloomFoundation

struct OnboardingLoginView: View {
  let onContinue: () -> Void

  @State private var index = 0
  @State private var authorizationState: String?
  @State private var error: Error?

  @State private var viewModel = ViewModel()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        BudImage(.budPhone, dimension: 200)
          .horizontalAlignment(.leading)

        Text("Let's sign in with your Apple Account.")
          .fixedSize(horizontal: false, vertical: true)
          .onboardingTextStyle()
          .horizontalAlignment(.leading)
          .padding(.horizontal)
          .transition(.opacity)
          .appear(with: 1, currentIndex: index, secondaryIfNotCurrentIndex: false)

        Text("This will let me keep your data safe, block spam, and run things smoothly. Don’t worry, your info stays private unless you choose to share it.")
          .font(.headline)
          .fixedSize(horizontal: false, vertical: true)
          .onboardingTextStyle()
          .horizontalAlignment(.leading)
          .padding(.horizontal)
          .transition(.opacity)
          .appear(with: 2, currentIndex: index, secondaryIfNotCurrentIndex: false)

        BloomPlusFeaturesListView()
          .fixedSize(horizontal: false, vertical: true)
          .transition(.blurReplace)
          .appear(with: 3, currentIndex: index, secondaryIfNotCurrentIndex: false)
      }
      .horizontallyCentered()
    }
    .groupedBackground()
    .animation(.default, value: index)
    .sensoryFeedback(.selection, trigger: index)
    .alert(error: $error)
    .shelf {
      Group {
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

        HStack {
          Link("Terms of Service", destination: .termsOfService)
            .frame(height: 44)

          Text("•")

          Link("Privacy Policy", destination: .privacyPolicy)
            .frame(height: 44)
        }
        .foregroundStyle(.tint)
        .bold()
      }
      .appear(with: 3, currentIndex: index, secondaryIfNotCurrentIndex: false)
    }
    .onAppear {
      TelemetryDeck.signal("View Login")
    }
    .task {
      while index < 3 {
        await advanceIndex()
      }
    }
  }
}

private extension OnboardingLoginView {

  func advanceIndex() async {
    await Delay(1000)

    index += 1
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
            TelemetryDeck.signal("Did Log In")
            await MainActor.run {
              onContinue()
            }
          } catch {
            TelemetryDeck.errorOccurred(
              id: "OnboardingLoginView.authenticate",
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
  PreviewEnvironment {
    OnboardingLoginView { }
  }
}
