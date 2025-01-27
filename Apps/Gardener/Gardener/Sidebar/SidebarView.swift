//
//  SidebarView.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-11-29.
//

import SwiftUI

struct SidebarView: View {

  @State private var showOptions = false
  
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    List {
      NavigationLink {
        FoodItemVerificationView()
      } label: {
        createLabel(
          title: "Food Item Verification",
          systemImage: "fork.knife"
        )
      }
      NavigationLink {
        BulkDataUploaderView()
      } label: {
        createLabel(
          title: "Bulk Data Uploader",
          systemImage: "tray.and.arrow.up"
        )
      }
      NavigationLink {
        FoodItemSearchView()
      } label: {
        createLabel(
          title: "Food Search",
          systemImage: "magnifyingglass"
        )
      }
    }
    .shelf {
      metadataView
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          openWindow(id: .WindowGroup.createNewFoodItem)
        } label: {
          Image(systemName: "plus")
        }
        .accessibilityLabel("Add food item")
      }
    }
  }
}

private extension SidebarView {
  var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
  }

  var buildNumber: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
  }

  var metadataView: some View {
    VStack(spacing: 8) {
      Text("Version \(appVersion) (\(buildNumber))")
        .font(.caption)
        .bold()
        .foregroundStyle(.secondary)
    }
  }

  func createLabel(title: String, systemImage: String) -> some View {
    Label(
      title,
      systemImage: systemImage
    )
    .font(.title2)
    .padding(.vertical, 8)
  }
}

#Preview {
    SidebarView()
}
