//
//  WeatherCurrentConditionsCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-29.
//

import SwiftUI
import WeatherKit

struct WeatherCurrentConditionsCell: View {
    let symbolName: String
    let temperature: String
    let conditions: String
    let locality: String

    init(currentWeather: CurrentWeather, locality: String) {
        self.init(
            symbolName: currentWeather.symbolName,
            temperature: currentWeather.temperature.formatted(.measurement(width: .narrow, numberFormatStyle: .number.precision(.fractionLength(0)))),
            conditions: currentWeather.condition.description,
            locality: locality
        )
    }

    init(
        symbolName: String,
        temperature: String,
        conditions: String,
        locality: String
    ) {
        self.symbolName = symbolName
        self.temperature = temperature
        self.conditions = conditions
        self.locality = locality
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                HStack {
                    Text(temperature)
                    Image(systemName: symbolName)
                }
                .font(.title)
                .fontDesign(.rounded)
                .bold()

                Text(conditions)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }

            Spacer()

            HStack(spacing: 2) {
                Image(systemName: "location")
                Text(locality)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    List {
        WeatherCurrentConditionsCell(
            symbolName: "moon.stars",
            temperature: "26º",
            conditions: "Clear",
            locality: "Waterloo"
        )
    }
    .listStyle(.plain)
}
