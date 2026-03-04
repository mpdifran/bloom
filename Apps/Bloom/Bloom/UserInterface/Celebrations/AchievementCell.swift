//
//  AchievementCell.swift
//  Bloom
//
//  Created by Claude on 2026-03-04.
//

import SwiftUI

struct AchievementCell: View {

  let record: AchievementRecord
  let imageURL: URL?

  var body: some View {
    VStack(spacing: 8) {
      if let imageURL {
        AsyncImage(url: imageURL) { image in
          image
            .resizable()
            .scaledToFit()
        } placeholder: {
          RoundedRectangle(cornerRadius: 12)
            .fill(.quaternary)
            .aspectRatio(0.7, contentMode: .fit)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
      }

      Spacer(minLength: 0)

      Text(record.title)
        .font(.subheadline)
        .bold()
        .fontDesign(.rounded)
        .lineLimit(2)
        .multilineTextAlignment(.center)

      HStack(spacing: 6) {
        Image(systemName: "laurel.leading")
        Text(record.dateAchieved.formatted(.dateTime.month(.abbreviated).day().year()))
        Image(systemName: "laurel.trailing")
      }
      .font(.caption)
      .fontWeight(.bold)
      .fontDesign(.rounded)
      .foregroundStyle(.secondary)
    }
    .cardContainer()
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      AchievementCell(
        record: AchievementRecord(
          id: UUID(),
          dateAchieved: Date(),
          kindIdentifier: "biologicalAge.3",
          title: "3 Years Younger!",
          shareMessage: "My biological age is 3 years younger!",
          imageFileName: "test.jpg"
        ),
        imageURL: nil
      )
      .frame(width: 180)
    }
  }
}
