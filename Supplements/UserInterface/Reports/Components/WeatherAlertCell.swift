//
//  WeatherAlertCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-29.
//

import SwiftUI
import WeatherKit

struct WeatherAlertCell: View {
    let source: String
    let summary: String
    let detailsURL: URL
    let severity: WeatherSeverity
    let region: String?

    init(weatherAlert: WeatherAlert) {
        self.init(
            source: weatherAlert.source,
            summary: weatherAlert.summary,
            detailsURL: weatherAlert.detailsURL,
            severity: weatherAlert.severity,
            region: weatherAlert.region
        )
    }

    init(
        source: String,
        summary: String,
        detailsURL: URL,
        severity: WeatherSeverity,
        region: String?
    ) {
        self.source = source
        self.summary = summary
        self.detailsURL = detailsURL
        self.severity = severity
        self.region = region
    }

    var body: some View {
        HStack {
            if let systemImage = severity.systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(.white, severity.color)
                    .font(.title)
            }

            VStack(alignment: .leading) {
                if let name = severity.name {
                    Text(name)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(severity.color)
                }

                Text(summary)

                Link(destination: detailsURL) {
                    Text("Source: \(source)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            Spacer()
        }
    }
}

extension WeatherSeverity {

    var name: String? {
        switch self {
        case .minor: "Minor Alert"
        case .moderate: "Moderate Alert"
        case .severe: "Severe Alert"
        case .extreme: "Extreme Alert"
        default: nil
        }
    }

    var systemImage: String? {
        switch self {
        case .minor: "info.circle.fill"
        case .moderate: "exclamationmark.circle.fill"
        case .severe: "exclamationmark.triangle.fill"
        case .extreme: "exclamationmark.octagon.fill"
        default: nil
        }
    }

    var color: Color {
        switch self {
        case .minor: .blue
        case .moderate: .orange
        case .severe: .yellow
        case .extreme: .red
        default: .clear
        }
    }
}

#Preview {
    List {
        WeatherAlertCell(
            source: "The Weather Channel",
            summary: "There's a tornado watch in your area.",
            detailsURL: URL(string: "https://www.apple.ca")!,
            severity: .severe,
            region: "Waterloo"
        )
    }
    .listStyle(.plain)
}
