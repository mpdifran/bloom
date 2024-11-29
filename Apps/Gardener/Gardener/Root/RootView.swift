//
//  RootView.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-11-29.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 150, ideal: 200, max: 300)
        } detail: {
            Text("Hello World")
        }
    }
}

#Preview {
    RootView()
}
