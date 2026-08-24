//
//  SafariPresenter.swift
//  Bloom
//

import UIKit
import SwiftUI
import SafariServices

/// Opens a link in an in-app browser, presented through UIKit.
///
/// Not a `UIViewControllerRepresentable` inside a `.fullScreenCover`, which is the obvious SwiftUI
/// way and does not work here: `SFSafariViewController` is documented as unsupported as a child
/// view controller, and that is exactly what wrapping it in a representable makes it. Inside chat -
/// SwiftUI cells hosted in a UIKit collection view - it presents and then renders nothing but
/// white.
///
/// Presenting it from the top-most view controller keeps it a proper modal, which is the only
/// arrangement it supports.
enum SafariPresenter {

  static func open(_ url: URL, tint: Color) {
    // Anything that isn't web content would present an empty browser. Better to hand it to the
    // system, which may have an app registered for it.
    guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
      UIApplication.shared.open(url)
      return
    }

    guard let presenter = topViewController() else {
      UIApplication.shared.open(url)
      return
    }

    let controller = SFSafariViewController(url: url)
    controller.preferredControlTintColor = UIColor(tint)
    presenter.present(controller, animated: true)
  }

  /// The view controller currently on screen, following presentations, navigation and tabs down to
  /// whatever is actually frontmost.
  private static func topViewController() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
      ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first

    guard let root = scene?.windows.first(where: \.isKeyWindow)?.rootViewController else {
      return nil
    }

    var top = root
    while true {
      if let presented = top.presentedViewController {
        top = presented
      } else if let navigation = top as? UINavigationController, let visible = navigation.visibleViewController {
        top = visible
      } else if let tab = top as? UITabBarController, let selected = tab.selectedViewController {
        top = selected
      } else {
        return top
      }
    }
  }
}
