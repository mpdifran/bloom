//
//  FeatureRequestWebView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-05.
//

import SwiftUI
import WebKit

struct FeatureRequestWebView: UIViewRepresentable {

    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject private var healthManager = HealthManager.shared

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(
            url: .featureRequests(
                userID: UserID.value,
                name: healthManager.name,
                isDark: colorScheme == .dark
            )
        )
        uiView.load(request)
    }
}

#Preview {
    FeatureRequestWebView()
}
