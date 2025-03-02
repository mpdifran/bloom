//
//  WorkoutActivityTypeFilterView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-19.
//

import SFSafeSymbols
import SwiftUI
import HealthKit

struct WorkoutActivityTypeFilterView: View {
  let activityTypes: [HKWorkoutActivityType]
  @Binding var selectedActivityType: HKWorkoutActivityType?

  var body: some View {
    ScrollViewReader { scrollReader in
      ScrollView(.horizontal) {
        HStack {
          ActivityTypeCell(title: "All", symbol: .figure, isSelected: selectedActivityType == nil)
            .id("All")
            .onTapGesture {
              selectedActivityType = nil
              withAnimation {
                scrollReader.scrollTo("All", anchor: .center)
              }
            }

          ForEach(activityTypes, id: \.self) { activityType in
            ActivityTypeCell(
              title: activityType.name,
              symbol: SFSymbol(rawValue: activityType.systemImage),
              isSelected: selectedActivityType == activityType
            )
            .id(activityType.name)
            .onTapGesture {
              selectedActivityType = activityType
              withAnimation {
                scrollReader.scrollTo(activityType.name, anchor: .center)
              }
            }
          }
        }
        .padding()
      }
      .onAppear {
        if let activityType = selectedActivityType {
          scrollReader.scrollTo(activityType.name, anchor: .center)
        }
      }
    }
    .scrollIndicators(.hidden)
    .animation(.easeInOut, value: selectedActivityType)
    .sensoryFeedback(.selection, trigger: selectedActivityType)
  }
}

private struct ActivityTypeCell: View {
  let title: String
  let symbol: SFSymbol
  let isSelected: Bool

  var body: some View {
    HStack {
      Image(systemSymbol: symbol)
      Text(title)
    }
    .bold()
    .foregroundStyle(isSelected ? .white : .text)
    .padding(.horizontal, 20)
    .frame(minHeight: 50)
    .background {
      Capsule()
        .fill(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill))
    }
    .selectable()
  }
}

#Preview {
  @Previewable @State var selectedActivityType: HKWorkoutActivityType?

  NavigationStack {
    ScrollView {
      VStack {
        WorkoutActivityTypeFilterView(
          activityTypes: [.running, .rugby, .climbing, .archery, .badminton],
          selectedActivityType: $selectedActivityType
        )
        .tint(.green)
      }
    }
    .navigationTitle("Activity Type Filter View")
  }
}
