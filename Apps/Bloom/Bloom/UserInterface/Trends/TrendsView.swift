//
//  TrendsView.swift
//  Bloom
//
//  Created by Claude on 2025-12-12.
//

import SwiftUI
import SFSafeSymbols
import BloomUI

struct TrendsView: View {
  @State private var presentedSheet: AnyView?

  /// Available Year In Bloom years (2025+, current year only after Dec 15)
  private var availableYears: [Int] {
    let calendar = Calendar.current
    let now = Date.now
    let currentYear = calendar.component(.year, from: now)
    let currentMonth = calendar.component(.month, from: now)
    let currentDay = calendar.component(.day, from: now)

    var years: [Int] = []

    // Add all previous years starting from 2025
    for year in 2025..<currentYear {
      years.append(year)
    }

    // Add current year only if it's Dec 15 or later
    if currentMonth == 12 && currentDay >= 15 && currentYear >= 2025 {
      years.append(currentYear)
    }

    return years.sorted(by: >)  // Most recent first
  }

  var body: some View {
    NavigationStack {
      BloomScrollView {
        ForEach(availableYears, id: \.self) { year in
          Button {
            presentedSheet = YearInBloomStoriesView(year: year).asAny
          } label: {
            HStack {
              Text("\(year) Year in Bloom")
                .bold()
              Spacer()
              DisclosureIndicator()
            }
            .cardContainer()
          }
          .buttonStyle(.plain)
        }
      }
      .navigationTitle("Trends")
      .sheet($presentedSheet)
    }
    .tabItem {
      Label("Trends", systemSymbol: .chartXyaxisLine)
    }
  }
}

extension TrendsView {

  func gradientColors(for year: Int) -> [Color] {
    switch year {
    case 2025:
      [.mutedLightBlue, .green, .mint]
    default:
      [.green, .teal, .mint]
    }
  }
}

#Preview {
  PreviewEnvironment {
    TabView {
      TrendsView()
    }
  }
}
