//
//  AllDayEventCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-30.
//

import SFSafeSymbols
import SwiftUI
import EventKit

struct AllDayEventCell: View {
    let event: EKEvent

    var body: some View {
        HStack {
            Capsule()
                .fill(Color(event.calendar.cgColor))
                .frame(width: 4)
                .padding(.vertical, 6)

            VStack(alignment: .leading) {
                Text(event.title)
                    .font(.headline)
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
    }
}

#Preview {
    List {
        AllDayEventCell(event: .allDayPreview)
    }
    .listStyle(.plain)
}
