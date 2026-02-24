//
//  DebugSoundsView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-02-24.
//

import SwiftUI
import SFSafeSymbols

#if DEBUG
struct DebugSoundsView: View {

  private let sounds: [(name: String, action: () -> Void)] = [
    ("Workout Countdown", { SoundPlayer.playWorkoutCountdown() }),
    ("Log Health Data (Haptic)", { SoundPlayer.playLogHealthData() })
  ]

  var body: some View {
    List {
      ForEach(Array(sounds.enumerated()), id: \.offset) { _, sound in
        Button {
          sound.action()
        } label: {
          HStack {
            Text(sound.name)
              .font(.caption)
              .bold()
              .fontDesign(.rounded)

            Spacer()

            Image(systemSymbol: .speakerWave2Fill)
              .foregroundStyle(.tint)
          }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 10)
      }
    }
    .listStyle(.carousel)
    .navigationTitle("Sounds")
  }
}

#Preview {
  PreviewEnvironment {
    DebugSoundsView()
  }
}
#endif
