//
//  FoodLogDatePicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-25.
//

import SwiftUI
import BloomFoundation
import CoreHealth

struct FoodLogDatePicker: View {
  @Binding var date: Date
  let stateForDate: (Date) -> FoodLogDateState

  init(
    date: Binding<Date>,
    stateForDate: @escaping (Date) -> FoodLogDateState
  ) {
    self._date = date
    self._internalDate = State(initialValue: date.wrappedValue)
    self._dates = State(
      initialValue: Calendar.current.dateCollection(
        for: .window(
          around: date.wrappedValue,
          numberOfDays: 30
        )
      )
    )
    self.stateForDate = stateForDate
  }

  @State private var internalDate: Date
  @State private var cardFrames = CardFrames()
  @State private var scrollID: String?
  @State private var dates: [Date]
  @State private var shouldControlScrollOffset = true
  @State private var viewWidth: CGFloat = 0

  private static let geometry = NamedCoordinateSpace.named("FoodLogDatePicker.geometry")

  var body: some View {
    TimelineView(.periodic(from: Calendar.current.startOfTomorrow(for: .now), by: 60)) { _ in
      VStack(alignment: .leading) {
        headerView

        ScrollViewReader { scrollViewProxy in
          ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
              ForEach(dates, id: \.self) { cellDate in
                Button {
                  withAnimation {
                    scrollID = "\(cellDate.timeIntervalSince1970)"
                  }
                } label: {
                  FoodLogDateCell(
                    date: cellDate,
                    state: stateForDate(cellDate),
                    isSelected: isSameDay(cellDate, internalDate)
                  )
                }
                .buttonStyle(.plain)
                .id("\(cellDate.timeIntervalSince1970)")
                .backgroundPreference(key: CardFrames.self) { proxy in
                  CardFrames(frames: [cellDate: proxy.frame(in: Self.geometry)])
                }
              }
            }
            .padding(.horizontal, viewWidth / 2)
            .coordinateSpace(Self.geometry)
            .scrollTargetLayout()
            .onScrollEnded(in: Self.geometry.coordinateSpace) { offset in
              self.date = internalDate
            }
          }
          .scrollTargetBehavior(
            CenterScrollTargetBehaviour(
              cardFrames: cardFrames,
              enabled: shouldControlScrollOffset
            )
          )
          .scrollPosition(id: $scrollID, anchor: .center)
        }
      }
    }
    .readViewSize { proxy in
      viewWidth = proxy.size.width
    }
    .onPreferenceChange(CardFrames.self) { newFrames in
      MainTask { cardFrames = newFrames }
    }
    .sensoryFeedback(.selection, trigger: internalDate)
    .onChange(of: scrollID) { oldValue, newValue in
      guard
        let newValue,
        let timeInterval = TimeInterval(newValue)
      else { return }

      internalDate = Date(timeIntervalSince1970: timeInterval)
    }
//    .onChange(of: date) { oldValue, newValue in
//      guard
//        let firstDate = dates.first,
//        let lastDate = dates.last,
//        date < firstDate || date > lastDate
//      else { return }
//
//      dates = Calendar.current.dateCollection(
//        for: .window(
//          around: newValue,
//          numberOfDays: 30
//        )
//      )
//      scrollID = "\(newValue.timeIntervalSince1970)"
//    }
    .onAppear {
      if let initialDate = dates.first(where: { isSameDay($0, internalDate) }) {
        scrollID = "\(initialDate.timeIntervalSince1970)"
      }
    }
  }
}

private extension FoodLogDatePicker {

  var headerView: some View {
    HStack {
      Text(DateFormatter.justDateLong.string(from: internalDate))
        .foregroundStyle(.secondary)
        .fontDesign(.rounded)
        .fontWeight(.bold)

      Spacer()

      Button {
        guard let today = dates.first(where: { isSameDay(.now, $0) }) else { return }

        shouldControlScrollOffset = false
        withAnimation {
          scrollID = "\(today.timeIntervalSince1970)"
        }
        Task {
          await Delay(500)
          await MainActor.run {
            shouldControlScrollOffset = true
          }
        }
      } label: {
        Text("Today")
          .bold()
      }
      .disabled(isSameDay(internalDate, .now))
    }
    .padding(.horizontal)
  }
}

private extension FoodLogDatePicker {

  func isSameDay(_ d1: Date, _ d2: Date) -> Bool {
    Calendar.current.isDate(d1, inSameDayAs: d2)
  }
}

private struct CardFrames: Equatable {
  var frames: [Date: CGRect] = [:]
}

extension CardFrames: PreferenceKey {
  static var defaultValue: Self { CardFrames() }

  static func reduce(value: inout Self, nextValue: () -> Self) {
    value.frames.merge(nextValue().frames) { $1 }
  }
}

private struct CenterScrollTargetBehaviour: ScrollTargetBehavior {
  let cardFrames: CardFrames
  let enabled: Bool

  func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
    guard enabled else { return }

    let xProposed = target.rect.midX + context.velocity.dx * 5
    guard let nearestEntry = cardFrames
      .frames
      .min(by: { ($0.value.midX - xProposed).magnitude < ($1.value.midX - xProposed).magnitude })
    else { return }

    target.rect.origin.x = nearestEntry.value.midX - 0.5 * target.rect.size.width
  }
}

#Preview {
  @Previewable @State var date: Date = .now

  PreviewEnvironment {
    ScrollView {
      VStack {
        FoodLogDatePicker(date: $date) { date in
            .inProgress(0.3)
        }
        .padding(.vertical)

        Text(DateFormatter.justDateLong.string(from: date))
      }
    }
    .groupedBackground()
  }
}
