//
//  View+ReadViewSize.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-19.
//

import SwiftUI

extension View {

  func readViewSize(_ handler: @escaping (GeometryProxy) -> Void) -> some View {
    self.background {
        GeometryReader { proxy in
          Color.clear
            .onChange(of: proxy.size) {
              handler(proxy)
            }
            .onAppear {
              handler(proxy)
            }
        }
      }
  }
}
