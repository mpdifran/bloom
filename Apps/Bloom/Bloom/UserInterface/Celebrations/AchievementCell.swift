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
          Rectangle()
            .fill(.fill)
            .aspectRatio(0.7, contentMode: .fit)
        }
      } else {
        Rectangle()
          .fill(.fill)
          .aspectRatio(0.7, contentMode: .fit)
      }

      Spacer(minLength: 0)

      VStack(spacing: 10) {
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
      .padding(.horizontal)
      .padding(.bottom)
    }
    .cardContainer(includePadding: false)
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
          title: "3 Years Younger and You're More Healthy!",
          shareMessage: "My biological age is 3 years younger!",
          imageFileName: "test.jpg"
        ),
        imageURL: nil
      )
      .frame(width: 180)
    }
  }
}
