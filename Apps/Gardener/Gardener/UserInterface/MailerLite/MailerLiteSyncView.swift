//
//  MailerLiteSyncView.swift
//  Gardener
//

import SwiftUI

struct MailerLiteSyncView: View {

  @State private var segmentResult: String?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        segmentSection
      }
      .padding()
    }
    .navigationTitle("MailerLite")
  }
}

// MARK: - Sections

private extension MailerLiteSyncView {

  var segmentSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Free User Segmentation")
        .font(.title2)
        .bold()

      Text("Identify loyal free users (30+ days, never paid) via RevenueCat and add them to the MailerLite group for discount emails.")
        .font(.subheadline)
        .foregroundColor(.secondary)

      AsyncButton {
        try await NetworkStack.shared.segmentFreeUsers()
        segmentResult = "Segmentation started in background. Check Heroku logs for progress."
      } label: {
        Text("Segment Free Users")
      }
      .buttonStyle(.borderedProminent)

      if let segmentResult {
        Text(segmentResult)
          .foregroundColor(.green)
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.green.opacity(0.1))
          .cornerRadius(8)
      }
    }
  }
}

#Preview {
  MailerLiteSyncView()
}
