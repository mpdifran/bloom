//
//  BowelMovementActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import SwiftData
import TelemetryDeck
import DataContainer

struct BowelMovementActionCardView: View {

  @State private var date = Date.now
  @State private var selectedStoolType: Int = 0
  @State private var duration: BowelMovement.Duration = .between5And10Min

  var body: some View {
    InsetCardView(includePadding: false) {
      LargeTitleActionCard("Log Bowel Movement") {
        HealthActionCardView(
          addPaddingToSaveButton: true
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
      Image(systemName: "questionmark.app.fill")
        .font(.largeTitle)

      Spacer(minLength: 0)
    }
    .frame(width: 130, height: 140)
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 13)
        .fill(.background.secondary)
    }
    .overlay {
      if selectedStoolType == 0 {
        RoundedRectangle(cornerRadius: 13)
          .stroke(.tint, lineWidth: 3)
      }
    }
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
    .padding(.horizontal)
    .padding(.vertical, 12)
    .cardContainer(fill: .background.secondary, includePadding: false)
    .padding(.horizontal)
  }

  var dateCell: some View {
    LabeledContent("Date") {
      DatePicker("", selection: $date)
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
    .cardContainer(fill: .background.secondary, includePadding: false)
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
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 13)
        .fill(.background.secondary)
    }
    .overlay {
      if isSelected {
        RoundedRectangle(cornerRadius: 13)
          .stroke(.tint, lineWidth: 3)
      }
    }
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
  PreviewSheetPresent {
    BowelMovementActionCardView()
  }
}
