//
//  ExternalHealthMetricPermissionCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-04.
//

import SwiftUI

struct ExternalHealthMetricPermissionCell: View {
  let permission: ExternalHealthMetricPermission

  @ObservedObject private var manager = ExternalHealthMetricPermissionManager.shared

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

      Toggle("", isOn: Binding(get: {
        manager.getIsEnabled(for: permission)
      }, set: { newValue in
        manager.set(isEnabled: newValue, for: permission)
      }))
        .layoutPriority(0)
        .foregroundStyle(.tint)
    }
  }
}

#Preview {
  ScrollView {
    VStack {
      ExternalHealthMetricPermissionCell(permission: .heartHealth)
      Divider()
      ExternalHealthMetricPermissionCell(permission: .heartHealth)
    }
    .cardContainer()
    .padding()
  }
  .groupedBackground()
  .tint(.mutedBlue)
}
