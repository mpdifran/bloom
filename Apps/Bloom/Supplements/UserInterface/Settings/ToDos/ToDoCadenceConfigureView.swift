//
//  ToDoCadenceConfigureView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-26.
//

import SwiftUI

struct ToDoCadenceConfigureView: View {
  @Binding var todo: ToDoModel

  var body: some View {
    ScrollView {
      VStack {
        Text(todo.kind.name)
          .font(.largeTitle)
          .bold()
          .fontDesign(.rounded)
          .minimumScaleFactor(0.3)
          .lineLimit(1)

        LabeledContent("Cadence") {
          Picker(selection: $todo.cadence) { // TODO: There's a bug with this
            ForEach(ToDoModel.Cadence.allCases) { cadence in
              Text(cadence.name)
                .tag(cadence)
            }
          } label: {
            Text(todo.cadence.name)
          }
        }
        .bold()
        .cardContainer()
      }
      .padding()
      .presentationDetentSelfSizing()
    }
    .groupedBackground()
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
  }
}

#Preview {
  @Previewable @State var todo = ToDoModel(
    kind: .logWeight,
    cadence: .everySunday,
    vitalKind: nil
  )

  PreviewSheetPresent {
    ToDoCadenceConfigureView(todo: $todo)
  }
}
