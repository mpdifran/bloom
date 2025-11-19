//
//  LogTagFilterView.swift
//  Bloom
//
//  Created by Assistant on 2025-01-26.
//

import SwiftUI
import AppUI

struct LogTagFilterView: View {
  @Binding var selectedTag: LogTag?
  @Environment(\.dismiss) private var dismiss

  // Local state to track picker selection before applying
  @State private var tempSelection: String = "all"

  var body: some View {
    CardView {
      VStack {
        // Header
        Text("Filter Logs")
          .font(.title2)
          .bold()
          .padding(.top)

        // Picker
        LabeledContent("Tag") {
          Picker("Tag", selection: $tempSelection) {
            Text("All").tag("all")
            ForEach(LogTag.allCases) { tag in
              Text(tag.rawValue).tag(tag.id)
            }
          }
          .pickerStyle(.menu)
        }
        .cardContainer()

        Button {
          // Apply the selection
          if tempSelection == "all" {
            selectedTag = nil
          } else {
            selectedTag = LogTag.allCases.first { $0.id == tempSelection }
          }
          dismiss()
        } label: {
          Text("Apply")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
      }
      .padding()
    }
    .onAppear {
      // Initialize temp selection from current filter
      if let tag = selectedTag {
        tempSelection = tag.id
      } else {
        tempSelection = "all"
      }
    }
  }
}

#Preview {
  @Previewable @State var selectedTag: LogTag?
  PreviewEnvironment {
    PreviewSheetPresent {
      LogTagFilterView(selectedTag: $selectedTag)
    }
  }
}
