//
//  MailerLiteSyncView.swift
//  Gardener
//

import SwiftUI

struct MailerLiteSyncView: View {

  @State private var syncResult: String?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 12) {
          Text("MailerLite Sync")
            .font(.title2)
            .bold()

          Text("Sync all user emails from the database to MailerLite. This runs automatically every day at 3 AM ET.")
            .font(.subheadline)
            .foregroundColor(.secondary)

          AsyncButton {
            try await NetworkStack.shared.syncMailerLiteSubscribers()
            syncResult = "Sync completed successfully."
          } label: {
            Text("Sync Now")
          }
          .buttonStyle(.borderedProminent)

          if let syncResult {
            Text(syncResult)
              .foregroundColor(.green)
              .padding()
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(Color.green.opacity(0.1))
              .cornerRadius(8)
          }
        }
      }
      .padding()
    }
    .navigationTitle("MailerLite")
  }
}

#Preview {
  MailerLiteSyncView()
}
