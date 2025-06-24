import SwiftUI
import SFSafeSymbols

struct SoundDebugView: View {
  @Environment(\.dismiss) private var dismiss

  private let sounds: [(name: String, action: () -> Void)] = [
    // Workout sounds
    ("Workout Countdown", { SoundPlayer.playWorkoutCountdown() }),
    ("Interval Upcoming", { SoundPlayer.playIntervalUpcoming() }),
    ("Interval Ended", { SoundPlayer.playIntervalEnded() }),
    ("Workout Pace Above", { SoundPlayer.playWorkoutPaceAbove() }),
    ("Workout Autodetected", { SoundPlayer.playWorkoutAutodetected() }),

    // Activity/Goal sounds
    ("Activity Goal Close", { SoundPlayer.alertActivityGoalClose() }),
    ("Activity Goal Behind", { SoundPlayer.alertActivityGoalBehind() }),

    // Health data
    ("Log Health Data", { SoundPlayer.playLogHealthData() }),
    ("Health Reading Fail", { SoundPlayer.healthReadingFail() }),

    // Head gestures
    ("Head Gesture Double Shake", { SoundPlayer.playHeadGestureDoubleShake() }),
    ("Head Gesture Double Nod", { SoundPlayer.playHeadGestureDoubleNod() }),

    // Messages
    ("Send Message", { Task { @MainActor in SoundPlayer.playSendMessage() } }),
    ("Receive Message", { Task { @MainActor in SoundPlayer.playReceiveMessage() } }),
    ("Sender Confirmation", { SoundPlayer.playSenderConfirmation() })
  ]

  var body: some View {
    NavigationStack {
      List {
        ForEach(Array(sounds.enumerated()), id: \.offset) { _, sound in
          Button {
            sound.action()
          } label: {
            HStack {
              Text(sound.name)
              Spacer()
              Image(systemSymbol: .speakerWave2Fill)
                .foregroundStyle(.tint)
            }
            .selectable()
            .padding(.vertical)
          }
          .buttonStyle(.plain)
        }
      }
      .navigationTitle("Sound Debug")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    SoundDebugView()
  }
}
