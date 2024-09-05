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

    @AppStorage("PreferencesView.user.name") private(set) var userName: String = ""

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(
            url: .featureRequests(
                userID: UserID.value,
                name: userName,
                isDark: colorScheme == .dark
            )
        )
        uiView.load(request)
    }
}

#Preview {
    FeatureRequestWebView()
}
