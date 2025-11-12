//
//  HealthDataConsentView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-10.
//

import SwiftUI
import AppUI
import BloomUI

struct HealthDataConsentView: View {
  var onContinue: () -> Void

  @State private var healthDataCloudOptIn = false

  var body: some View {
    NavigationStack {
      BloomScrollView(padding: .bottom) {
        ZStack {
          Image(.afternoonScenery)
            .resizable()
            .scaledToFit()
            .parallaxOverscroll()
            .zStackAlignment(.top)


          VStack(spacing: 20) {
            BudImage(.budCoach, dimension: 180)
            explanationSection
            cloudSection
          }
          .padding(.horizontal)
          .padding(.top, 160)
        }
      }
      .removeScrollEdgeEffect(shouldHide: true)
      .ignoresSafeArea(.all, edges: .top)
      .navigationBarTitleDisplayMode(.inline)
      .shelf {
        Text("By continuing, I confirm I’m the age of majority where I live and consent to Bloom’s use of my personal health data as described.")
          .font(.caption)
          .bold()
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.leading)
          .horizontalAlignment(.leading)
          .padding(.horizontal)

        AsyncButton {
          onContinue()
        } label: {
          Text("Accept and Continue")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)

        privacyEmailView
      }
    }
  }
}

private extension HealthDataConsentView {

  var privacyEmailView: some View {
    HStack {
      Link("Privacy Policy", destination: .privacyPolicy)
        .bold()
        .frame(height: 40)
        .horizontallyCentered()

      Link("Questions? Email Us!", destination: .emailBloom(subject: "Privacy Questions"))
        .bold()
        .frame(height: 40)
        .horizontallyCentered()
    }
    .font(.subheadline)
  }

  @ViewBuilder
  var explanationSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(.healthAppIcon)
          .resizable()
          .frame(square: 40)
        Text("Your Data, Your Choice")
          .font(.title)
          .bold()
          .fontDesign(.rounded)
        Spacer()
      }

      Text("Bloom uses your Apple Health data to provide personalized insights and help you track goals. You are in full control of what data you would like to share.")
        .font(.body)
        .multilineTextAlignment(.leading)
    }
    .fixedSize(horizontal: false, vertical: true)
  }

  @ViewBuilder
  var cloudSection: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("Share Data Externally")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .bold()

//        Text("OPTIONAL")
//          .font(.system(size: 10))
//          .fontWeight(.heavy)
//          .padding(2)
//          .padding(.horizontal, 6)
//          .background {
//            Capsule()
//              .fill(.mutedBlue)
//          }
      }
      .padding(.horizontal)

      Toggle("Bud Insights", isOn: $healthDataCloudOptIn)
        .fixedSize(horizontal: false, vertical: true)
        .bold()
        .cardContainer()

      Text("""
          Features like Chat with Bud, Today Insights, and Biological Age send limited, summarized data to Bloom’s servers for processing. Your health data is never stored on our servers.
          """)
      .bold()
      .foregroundStyle(.secondary)
      .font(.caption)
      .padding(.horizontal)
    }
    .fixedSize(horizontal: false, vertical: true)
  }
}

#Preview {
  PreviewEnvironment {
    HealthDataConsentView() { }
  }
}
