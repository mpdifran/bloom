//
//  BulkDataUploaderView.swift
//  Gardener
//
//  Created by Zach Radford on 2024-11-29.
//

import SwiftUI

struct BulkDataUploaderView: View {

  var body: some View {
    Form {
      NavigationLink {
        OpenFoodFactsBulkUploader()
      } label: {
        Text("Open Food Facts")
      }
    }
    .formStyle(.grouped)
  }
}

#Preview {
  NavigationSplitView {
    BulkDataUploaderView()
  } detail: {
    Text("Nothing Selected")
  }
}
