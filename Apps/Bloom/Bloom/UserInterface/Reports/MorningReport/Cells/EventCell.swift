//
//  EventCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-25.
//

import SFSafeSymbols
import SwiftUI
import EventKit

struct EventCell: View {
  let event: EKEvent

  var body: some View {
    TimelineView(.everyMinute) { context in
      HStack {
        Capsule()
          .fill(event.hasCompleted ? .gray : Color(event.calendar.cgColor))
          .frame(width: 4)
          .padding(.vertical, 2)

        VStack(alignment: .leading) {
          Text(event.title)
            .font(.headline)
            .bold()

          if let location = event.structuredLocation?.title {
            if let url = URL(string: location), let host = url.host() {
              HStack(alignment: .firstTextBaseline, spacing: 2) {
                Image(systemSymbol: .video)
                  .font(.caption)

                Text(host)
              }
              .foregroundStyle(.secondary)
            } else {
              HStack(alignment: .firstTextBaseline, spacing: 2) {
                Image(systemSymbol: .location)
                  .font(.caption)

                Text(location)
              }
              .foregroundStyle(.secondary)
            }
          }

          if event.isStartingSoon, let durationText = DateFormatter.timeIntervalHourMinuteFull.string(from: event.startDate.timeIntervalSinceNow) {

            Text("Starting in \(durationText)")
              .foregroundStyle(.secondary)
              .contentTransition(.numericText(countsDown: true))
          }
          if event.hasStarted, let durationText = DateFormatter.timeIntervalHourMinuteFull.string(from: event.endDate.timeIntervalSinceNow) {
            Text("Ending in \(durationText)")
              .foregroundStyle(.secondary)
              .contentTransition(.numericText(countsDown: true))
          }
        }
        .font(.subheadline)

        Spacer()

        VStack(alignment: .trailing) {
          Text("\(event.startDate, formatter: DateFormatter.justTimeShort)")

          Text("\(DateFormatter.timeIntervalHourMinuteShort.string(from: event.duration) ?? "")")
            .foregroundStyle(.secondary)
        }
        .font(.subheadline)
      }
      .opacity(event.hasCompleted ? 0.4 : 1)
      .animation(.default, value: event.hasCompleted)
      .animation(.default, value: event.hasStarted)
      .animation(.default, value: event.isStartingSoon)
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      VStack {
        EventCell(event: .preview)
        EventCell(event: .futurePreview)
      }
      .cardContainer()
    }
  }
}
