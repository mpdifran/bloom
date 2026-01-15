//
//  BloomPlusBioAgeMeterView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-09-17.
//

import SwiftUI
import CoreHealth
import BloomUI

struct BloomPlusBioAgeMeterView: View {
  @State private var biologicalAge: Double? = nil

  private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

  var body: some View {
    VStack(alignment: .leading) {
      BiologicalAgeMeter(
        chronologicalAge: userAge,
        biologicalAge: biologicalAge
      )
      .frame(square: 150)
      .horizontallyCentered()

      Text("Unlock Your True Age")
        .font(.headline)
        .bold()
        .fontDesign(.rounded)
        .fixedSize(horizontal: false, vertical: true)
        .horizontalAlignment(.leading)

      Text("Bloom estimates your true biological age from your health habits. Spoiler: it might be younger than you think.")
        .font(.headline)
        .foregroundStyle(.secondary)
        .fontDesign(.rounded)
        .horizontalAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
    .cardContainer()
    .onAppear {
      biologicalAge = randomBiologicalAge()
    }
    .onReceive(timer) { _ in
      biologicalAge = randomBiologicalAge()
    }
  }
}

private extension BloomPlusBioAgeMeterView {

  var userAge: Double {
    let birthYear = HealthDefaults.shared.getBirthYear()
    guard birthYear > 0 else { return 30 }

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
      years += Double(max(0, monthsSinceBirthday)) / 12.0
    } else {
      let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
      let daysInYear = calendar.range(of: .day, in: .year, for: now)?.count ?? 365
      years += Double(dayOfYear - 1) / Double(daysInYear)
    }

    return years > 5 ? years : 30
  }

  func randomBiologicalAge() -> Double {
    let randomOffset = Double.random(in: -5...5)
    return userAge + randomOffset
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BloomPlusBioAgeMeterView()
    }
  }
}
