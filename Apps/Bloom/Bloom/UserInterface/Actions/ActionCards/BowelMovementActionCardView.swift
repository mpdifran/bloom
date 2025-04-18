//
//  BowelMovementActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import SFSafeSymbols
import SwiftData
import TelemetryDeck
import DataContainer

struct BowelMovementActionCardView: View {

  let performDismiss: (() -> Void)?

  init(performDismiss: (() -> Void)?) {
    self.performDismiss = performDismiss
  }

  @State private var date = Date.now
  @State private var selectedStoolType: Int = 0
  @State private var duration: BowelMovement.Duration = .between5And10Min

  @Environment(\.requestReview) private var requestReview

  var body: some View {
    CardView {
      LargeTitleActionCard("Log Bowel Movement", includePadding: false) {
        HealthActionCardView(
          addPaddingToSaveButton: true,
          performDismiss: performDismiss
        ) {
          try await logBowelMovement()
        } content: { (_, _) in
          typePickerCell
          durationCell
          dateCell
        }
      }
      .padding(.vertical)
    }
    .tint(.brown)
  }
}

private extension BowelMovementActionCardView {

  var typePickerCell: some View {
    ScrollViewReader { proxy in
      ScrollView(.horizontal) {
        HStack {
          unknownTypeCell

          ForEach(1...7, id: \.self) { stoolType in
            StoolTypeCell(
              stoolType: stoolType,
              isSelected: selectedStoolType == stoolType
            )
            .onTapGesture {
              selectedStoolType = stoolType
            }
          }
        }
        .padding()
      }
      .scrollIndicators(.never)
      .onChange(of: selectedStoolType) { (_, newValue) in
        withAnimation {
          proxy.scrollTo(newValue, anchor: .center)
        }
      }
      .sensoryFeedback(.selection, trigger: selectedStoolType)
    }
  }

  var unknownTypeCell: some View {
    VStack {
      Spacer(minLength: 0)
      Text("Unknown")
        .font(.subheadline)
        .bold()
      Spacer(minLength: 0)
      Image(systemSymbol: .questionmarkAppFill)
        .font(.largeTitle)

      Spacer(minLength: 0)
    }
    .frame(width: 130, height: 140)
    .cardContainer(stroke: selectedStoolType == 0 ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear))
    .id(0)
    .onTapGesture {
      selectedStoolType = 0
    }
  }

  var durationCell: some View {
    LabeledContent("Duration") {
      Picker("", selection: $duration) {
        ForEach(BowelMovement.Duration.allCases) { duration in
          Text(duration.name)
            .tag(duration)
        }
      }
    }
    .cardContainer()
    .padding(.horizontal)
  }

  var dateCell: some View {
    LabeledContent("Date") {
      DatePicker("", selection: $date)
    }
    .cardContainer()
    .padding(.horizontal)
  }
}

private extension BowelMovementActionCardView {

  func logBowelMovement() async throws -> Bool {
    let context = ContainerHolder.shared.createContext()
    let model = BowelMovement(
      date: date,
      bristolStoolType: selectedStoolType,
      duration: duration
    )
    context.insert(model)
    try context.save()

    await VitalsCalculator.shared.fetchSwiftDataTypes()

    TelemetryDeck.signal("Log Bowel Movement")

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }

    return true
  }
}

private struct StoolTypeCell: View {
  let stoolType: Int
  let isSelected: Bool

  var body: some View {
    VStack {
      Text("Type \(stoolType)")
        .font(.subheadline)
        .bold()
      Image("Type \(stoolType)")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 13))

      Spacer()

      Text(description(for: stoolType))
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.center)
        .lineLimit(3)
    }
    .frame(width: 130, height: 140)
    .cardContainer(stroke: isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear))
  }

  func description(for type: Int) -> String {
    switch type {
    case 1: "Separate hard lumps, hard to pass"
    case 2: "Sausage shape but lumpy"
    case 3: "Like a sausage but with cracks"
    case 4: "Like a sausage, smooth and long"
    case 5: "Soft blobs with clear cut edges"
    case 6: "Mushy consistency with ragged edges"
    case 7: "Liquid consistency with no solid pieces"
    default: ""
    }
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      BowelMovementActionCardView(performDismiss: nil)
    }
  }
}
