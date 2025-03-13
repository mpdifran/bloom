//
//  ExternalHealthMetricPermissionCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-04.
//

import SwiftUI

struct ExternalHealthMetricPermissionCell: View {
  let permission: ExternalHealthMetricPermission
  @Binding var isEnabled: Bool

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(permission.name)
          .bold()
        Text(permission.description)
          .foregroundStyle(.secondary)
      }
      .fontDesign(.rounded)
      .layoutPriority(10)

      Spacer()

      Toggle("", isOn: $isEnabled)
        .layoutPriority(0)
        .foregroundStyle(.tint)
    }
  }
}

#Preview {
  @Previewable @State var isHeartEnabled = true
  @Previewable @State var isBodyEnabled = false
  ScrollView {
    VStack {
      ExternalHealthMetricPermissionCell(
        permission: .heartHealth,
        isEnabled: $isHeartEnabled
      )
      Divider()
      ExternalHealthMetricPermissionCell(
        permission: .bodyComposition,
        isEnabled: $isBodyEnabled
      )
    }
    .cardContainer()
    .padding()
  }
  .groupedBackground()
  .tint(.mutedBlue)
}
