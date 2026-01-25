//
//  BioAgeTabView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-25.
//

import SwiftUI
import CoreHealth
import BloomUI

struct BioAgeTabView: View {
  @State private var biologicalAge: Double?
  @State private var chronologicalAge: Double = 0
  @State private var lastCalculated: Date?

  var body: some View {
    VStack(spacing: 8) {
      BiologicalAgeMeter(
        chronologicalAge: chronologicalAge,
        biologicalAge: biologicalAge
      )
      .frame(width: 140, height: 140)

      if let lastCalculated {
        Text("Updated \(lastCalculated, style: .relative) ago")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      } else if biologicalAge == nil {
        Text("Open Bloom on iPhone to calculate")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .task {
      loadBioAge()
    }
  }

  private func loadBioAge() {
    // Calculate chronological age from HealthDefaults
    let birthYear = HealthDefaults.shared.getBirthYear()
    guard birthYear > 0 else { return }

    let birthMonth = HealthDefaults.shared.getBirthMonth()
    let calendar = Calendar.current
    let now = Date.now
    let currentYear = calendar.component(.year, from: now)
    let currentMonth = calendar.component(.month, from: now)
    let currentDay = calendar.component(.day, from: now)

    var years = Double(currentYear - birthYear)

    if birthMonth > 0 {
      let monthsSinceBirthday: Int
      if currentMonth > birthMonth || (currentMonth == birthMonth && currentDay >= 15) {
        monthsSinceBirthday = currentMonth - birthMonth + (currentDay >= 15 ? 0 : -1)
      } else {
        years -= 1
        monthsSinceBirthday = 12 - birthMonth + currentMonth + (currentDay >= 15 ? 0 : -1)
      }
      chronologicalAge = years + (Double(max(0, monthsSinceBirthday)) / 12.0)
    } else {
      let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
      let daysInYear = calendar.range(of: .day, in: .year, for: now)?.count ?? 365
      chronologicalAge = years + (Double(dayOfYear - 1) / Double(daysInYear))
    }

    // Load cached biological age result from UserDefaults
    // iOS stores the result that we can read
    if let data = UserDefaults.standard.data(forKey: "BiologicalAgeCalculator.lastResult"),
       let result = try? JSONDecoder().decode(BiologicalAgeResult.self, from: data) {
      biologicalAge = result.biologicalAge
      lastCalculated = result.lastCalculated
    }
  }
}

#Preview {
  BioAgeTabView()
}
