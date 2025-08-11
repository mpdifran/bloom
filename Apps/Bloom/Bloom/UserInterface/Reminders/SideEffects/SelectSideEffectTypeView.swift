import SwiftUI
import AppUI
import DataContainer
import BloomFoundation
import SFSafeSymbols

struct SelectSideEffectTypeView: View {
  @Environment(\.dismiss) private var dismiss

  let onSave: (ReminderSideEffect) -> Void

  @State private var presentedSheet: AnyView?

  var body: some View {
    CardView {
      LargeTitleActionCard("Choose Side Effect") {
        VStack(spacing: 0) {
          ForEach(SideEffectType.allCases, id: \.self) { type in
            HStack {
              Image(systemSymbol: icon(for: type))
                .foregroundStyle(.accent)
                .font(.largeTitle)
                .frame(width: 50)

              VStack(alignment: .leading, spacing: 4) {
                Text(title(for: type))
                  .font(.body)
                  .fontWeight(.medium)
                  .fontDesign(.rounded)

                Text(description(for: type))
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .multilineTextAlignment(.leading)
              }

              Spacer()

              Image(systemSymbol: .chevronRight)
                .foregroundStyle(.tertiary)
                .font(.caption)
            }
            .padding(.vertical, 12)
            .selectable()
            .onTapGesture {
              select(sideEffect: type)
            }

            if type != SideEffectType.allCases.last {
              Divider()
                .padding(.leading, 44)
            }
          }
        }
        .cardContainer()
      }
    }
    .sheet($presentedSheet)
  }
}

private extension SelectSideEffectTypeView {

  func icon(for type: SideEffectType) -> SFSymbol {
    switch type {
    case .logFood:
      return .forkKnife
    case .logWater:
      return .waterbottle
    @unknown default:
      return .questionmark
    }
  }
  
  func title(for type: SideEffectType) -> String {
    switch type {
    case .logFood:
      return "Log Food"
    case .logWater:
      return "Log Water"
    @unknown default:
      return "Unknown Action"
    }
  }
  
  func description(for type: SideEffectType) -> String {
    switch type {
    case .logFood:
      return "Automatically log a food item when this reminder is completed."
    case .logWater:
      return "Automatically log water intake when this reminder is completed."
    @unknown default:
      return "Unknown action type"
    }
  }
}

private extension SelectSideEffectTypeView {

  func select(sideEffect: SideEffectType) {
    switch sideEffect {
    case .logFood:
      presentedSheet = ConfigureFoodSideEffectView { sideEffect in
        onSave(sideEffect)
        dismiss()
      }.asAny
    case .logWater:
      presentedSheet = ConfigureWaterSideEffectView { sideEffect in
        onSave(sideEffect)
        dismiss()
      }.asAny
    @unknown default:
      break
    }
  }
}

#Preview {
  PreviewSheetPresent {
    SelectSideEffectTypeView { sideEffect in

    }
  }
}
