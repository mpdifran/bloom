//
//  SidebarView.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-11-29.
//

import SwiftUI

struct SidebarView: View {
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
    }
}

private extension SidebarView {
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
