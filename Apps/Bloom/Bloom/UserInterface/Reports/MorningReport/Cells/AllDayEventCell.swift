//
//  AllDayEventCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-30.
//

import SFSafeSymbols
import SwiftUI
@preconcurrency import EventKit
import EventKitUI

struct AllDayEventCell: View {
  let event: EKEvent

  var body: some View {
    HStack {
//      Capsule()
//        .fill(Color(event.calendar.cgColor))
//        .frame(width: 4)
//        .padding(.vertical, 6)

      VStack(alignment: .leading) {
        Text(event.title)
          .bold()

        if let location = event.structuredLocation?.title {
          if let url = URL(string: location), let host = url.host() {
            HStack(spacing: 2) {
              Image(systemSymbol: .video)
                .font(.caption)

              Text(host)
            }
            .foregroundStyle(.secondary)
          } else {
            HStack(spacing: 2) {
              Image(systemSymbol: .location)
                .font(.caption)

              Text(location)
            }
            .foregroundStyle(.secondary)
          }
        }
      }
      .font(.subheadline)

      Spacer()

      Text("All Day")
        .foregroundStyle(.secondary)
        .font(.caption)
    }
    .foregroundStyle(.tint)
    .padding(8)
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(.tint.tertiary)
    }
    .compositingGroup()
    .tint(color)
  }
}

private extension AllDayEventCell {

  var color: Color {
    guard let calendar = event.calendar else { return .mutedBlue }

    return Color(calendar.cgColor)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      VStack {
        AllDayEventCell(event: .futurePreview)
      }
      .cardContainer()
    }
  }
}
