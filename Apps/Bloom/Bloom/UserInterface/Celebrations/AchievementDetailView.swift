//
//  AchievementDetailView.swift
//  Bloom
//
//  Created by Claude on 2026-03-04.
//

import SwiftUI
import TelemetryDeck

struct AchievementDetailView: View {

  let record: AchievementRecord
  let imageURL: URL

  @State private var isSharing = false
  @State private var x: Double = 1.0
  @State private var y: Double = 0.0
  @State private var angle: Double = 0.0
  @Environment(\.dismiss) private var dismiss

  private let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

  var body: some View {
    NavigationStack {
      VStack {
        Spacer()

        AsyncImage(url: imageURL) { image in
          image
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .rotation3DEffect(.degrees(3), axis: (x: x, y: y, z: 0))
            .shadow(color: .black.opacity(0.3), radius: 25, x: y * -10, y: x * 10)
        } placeholder: {
          RoundedRectangle(cornerRadius: 16)
            .fill(.quaternary)
            .aspectRatio(0.7, contentMode: .fit)
        }
        .padding(.horizontal, 32)

        Spacer()

        Button {
          isSharing = true
        } label: {
          Label("Share", systemImage: "square.and.arrow.up")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .padding(.horizontal)
        .padding(.bottom)
      }
      .navigationTitle(record.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
    }
    .presentationBackground(Color(uiColor: UIColor.secondarySystemBackground))
    .onReceive(timer) { _ in
      withAnimation(.linear(duration: 0.02)) {
        angle -= 0.02
        x = cos(angle)
        y = sin(angle)
      }
    }
    .sheet(isPresented: $isSharing) {
      ShareSheet(items: [imageURL, record.shareMessage]) { completed in
        guard completed else { return }
        TelemetryDeck.signal("Share Achievement", parameters: ["kind": record.kindIdentifier])
      }
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewSheetPresent {
    AchievementDetailView(
      record: AchievementRecord(
        id: UUID(),
        dateAchieved: Date(),
        kindIdentifier: "biologicalAge.3",
        title: "3 Years Younger!",
        shareMessage: "My biological age is 3 years younger!",
        imageFileName: "test.jpg"
      ),
      imageURL: URL(fileURLWithPath: "/tmp/test.jpg")
    )
  }
}
