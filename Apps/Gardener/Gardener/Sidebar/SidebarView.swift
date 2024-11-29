//
//  SidebarView.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-11-29.
//

import SwiftUI

struct SidebarView: View {
    var body: some View {
        Form {
            Text("Food Item Verification")
            Text("Bulk Data Uploader")
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SidebarView()
}
