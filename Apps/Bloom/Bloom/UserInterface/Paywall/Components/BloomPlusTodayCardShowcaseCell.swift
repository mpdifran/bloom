//
//  BloomPlusTodayCardShowcaseCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-09-03.
//

import SwiftUI
import BloomModel
import Combine
import BloomUI

struct BloomPlusTodayCardShowcaseCell: View {

  @State private var height: CGFloat = 1
  @State private var selectedIndex = 0
  
  private let timer = Timer.publish(every: 7, on: .main, in: .common).autoconnect()
  private let totalCards = 3

  var body: some View {
    TabView(selection: $selectedIndex) {
      BloomPlusTodayCardShowcaseCard(
        title: "Less guessing. More progressing.",
        message: "Every morning, Bud checks your sleep, activity, and recovery, then gives you one simple piece of advice to help you crush the day.") {
          TodaysAdviceTodayCell(advice: "Your recovery’s looking a little low today. Try to take it easy — swap intense workouts for something gentle, like a stretch or slow walk.")
        }
        .tag(0)
        .padding(.horizontal)
        .readViewSize { proxy in
          if proxy.size.height > height {
            self.height = proxy.size.height
          }
        }

      BloomPlusTodayCardShowcaseCard(
        title: "Less tossing. More snoozing.",
        message: "Every evening, Bud checks your recent sleep and activity, then gives you one simple tip to help you fall asleep faster and sleep more deeply.") {
          TonightsSleepTodayCell(recommendations: "Try putting your phone away by 9:30 PM tonight. Less screen time before bed = deeper, more refreshing sleep. Your brain will thank you tomorrow.")
        }
        .tag(1)
        .padding(.horizontal)
        .readViewSize { proxy in
          if proxy.size.height > height {
            self.height = proxy.size.height
          }
        }

      BloomPlusTodayCardShowcaseCard(
        title: "Less scrolling. More knowing.",
        message: "Bud scans your trends across sleep, activity, and nutrition, then gives you simple, actionable tips to help you feel your best, every day.") {
          VStack(alignment: .leading) {
            Text("Feeling Sluggish?")
              .font(.headline)
              .fontDesign(.rounded)
              .bold()
              .multilineTextAlignment(.leading)
            Text("Try adding more whole foods to lunch today — fiber and protein can help stabilize energy and mood all afternoon.")
              .font(.body)
              .fontDesign(.rounded)
              .fixedSize(horizontal: false, vertical: true)
            Spacer()
          }
          .foregroundStyle(.white)
          .horizontalAlignment(.leading)
          .cardContainer(
            fill: LinearGradient(
              colors: [
                .mutedBlue,
                .mutedGreen
              ],
              startPoint: .bottom,
              endPoint: .top
            )
          )
        }
        .tag(2)
        .padding(.horizontal)
        .readViewSize { proxy in
          if proxy.size.height > height {
            self.height = proxy.size.height
          }
        }
    }
    .tabViewStyle(.page(indexDisplayMode: .automatic))
    .frame(height: height)
    .onReceive(timer) { _ in
      withAnimation {
        selectedIndex = (selectedIndex + 1) % totalCards
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView(padding: []) {
      BloomPlusTodayCardShowcaseCell()
    }
  }
}
