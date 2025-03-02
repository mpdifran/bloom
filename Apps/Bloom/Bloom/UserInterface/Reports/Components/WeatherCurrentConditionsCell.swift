//
//  WeatherCurrentConditionsCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-29.
//

import SFSafeSymbols
import SwiftUI
import WeatherKit

struct WeatherCurrentConditionsCell: View {
  let symbol: SFSymbol
  let temperature: String
  let conditions: String
  let locality: String

  init(currentWeather: CurrentWeather, locality: String) {
    self.init(
      symbol: SFSymbol(rawValue: currentWeather.symbolName),
      temperature: currentWeather.temperature.formatted(
        .measurement(
          width: .narrow,
          numberFormatStyle: .number.precision(.fractionLength(0))
        )
      ),
      conditions: currentWeather.condition.description,
      locality: locality
    )
  }

  init(
    symbol: SFSymbol,
    temperature: String,
    conditions: String,
    locality: String
  ) {
    self.symbol = symbol
    self.temperature = temperature
    self.conditions = conditions
    self.locality = locality
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        HStack(alignment: .firstTextBaseline) {
          Text(temperature)
          Image(systemSymbol: symbol)
        }
        .font(.title)
        .fontDesign(.rounded)
        .bold()

        HStack(spacing: 2) {
          Image(systemSymbol: .location)
          Text(locality)
        }
        .font(.caption)
        .foregroundStyle(.secondary)


      }

      Spacer()

      Text(conditions)
        .bold()
    }
  }
}

#Preview {
  List {
    WeatherCurrentConditionsCell(
      symbol: .moonStars,
      temperature: "26º",
      conditions: "Clear",
      locality: "Waterloo"
    )
  }
  .listStyle(.plain)
}
