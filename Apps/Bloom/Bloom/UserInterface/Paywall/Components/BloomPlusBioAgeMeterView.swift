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

  var userAge: Int {
    let age = HealthDefaults.shared.getBirthday().toAge()
    return age > 5 ? age : 30
  }

  func randomBiologicalAge() -> Double {
    let randomOffset = Double.random(in: -5...5)
    return Double(userAge) + randomOffset
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BloomPlusBioAgeMeterView()
    }
  }
}
