//
//  ActionsList.swift
//  Bloom
//
//  Created by Claude on 2026-07-23.
//

import SwiftUI
import CoreHealth

/// The shared set of logging actions (Food, Drinks, Period, Weight, Bowel Movement, Blood Pressure).
/// Renders as a vertical list (the `ActionsView` sheet) or a 2-column grid of boxes (the Actions tab).
///
/// The parent owns the `presentedCardSheet` binding and attaches `.sheet($presentedCardSheet)`.
/// `onDismiss` is handed to each child card as its dismiss closure — the sheet dismisses itself to
/// return to the list (`{ presentedCardSheet = nil }`), or the whole Actions sheet (`{ dismiss() }`).
struct ActionsList: View {

  enum Layout {
    case list
    case grid
  }

  @Binding var presentedCardSheet: AnyView?
  let onDismiss: () -> Void
  var layout: Layout = .list

  private let columns = [
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12)
  ]

  var body: some View {
    switch layout {
    case .list:
      VStack {
        ForEach(items) { item in
          ActionInstanceCell(image: item.image, title: item.title)
            .tint(item.tint)
            .onTapGesture { presentedCardSheet = item.destination() }
        }
      }
    case .grid:
      LazyVGrid(columns: columns, spacing: 12) {
        ForEach(items) { item in
          ActionGridCell(image: item.image, title: item.title)
            .tint(item.tint)
            .onTapGesture { presentedCardSheet = item.destination() }
        }
      }
    }
  }

  private var items: [ActionItem] {
    var result: [ActionItem] = [
      ActionItem(image: .logFoodIcon, title: "Food", tint: .mutedGreen) {
        FoodLoggingActionCardView { onDismiss() }.asAny
      },
      ActionItem(image: .logWaterIcon, title: "Drinks", tint: .mutedBlue) {
        DrinkSelectionView(performDismiss: { onDismiss() }).asAny
      }
    ]

    if HealthManager.shared.sex() == .female {
      result.append(ActionItem(image: .logPeriodIcon, title: "Period", tint: .mutedPink) {
        CycleTrackingActionCardView { onDismiss() }.asAny
      })
    }

    result.append(contentsOf: [
      ActionItem(image: .logWeightIcon, title: "Weight", tint: .mutedIndigo) {
        BodyWeightActionCardView { onDismiss() }.asAny
      },
      ActionItem(image: .logBowelIcon, title: "Bowel Movement", tint: .brown) {
        BowelMovementActionCardView { onDismiss() }.asAny
      },
      ActionItem(image: .logBloodPressureIcon, title: "Blood Pressure", tint: .mutedRed) {
        BloodPressureActionCardView { onDismiss() }.asAny
      }
    ])

    return result
  }
}

// MARK: - Model

private struct ActionItem: Identifiable {
  var id: String { title }
  let image: ImageResource
  let title: String
  let tint: Color
  let destination: () -> AnyView
}

// MARK: - Grid cell

private struct ActionGridCell: View {
  let image: ImageResource
  let title: String

  var body: some View {
    VStack(spacing: 10) {
      HStack {
        Image(image)
          .resizable()
          .scaledToFit()
          .frame(width: 40, height: 40)

        Spacer()

        DisclosureIndicator()
      }

      Spacer()

      HStack {
        Text(title)
          .font(.headline)
          .bold()
          .fontDesign(.rounded)
          .multilineTextAlignment(.center)

        Spacer()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .foregroundStyle(.white)
    .cardContainer(fill: .tint)
    .aspectRatio(1.2, contentMode: .fit)
    .frame(maxWidth: .infinity)
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ActionsList(
        presentedCardSheet: .constant(nil),
        onDismiss: {},
        layout: .grid
      )
    }
  }
}
