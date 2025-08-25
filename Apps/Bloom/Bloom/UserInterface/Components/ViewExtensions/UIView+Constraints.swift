//
//  UIView+Constraints.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-25.
//

import UIKit

extension UIView {

  func constrainToParent(padding: CGFloat = 0) {
    guard let superview else {
      fatalError("This view needs to be added to a superview before calling this method!")
    }

    NSLayoutConstraint.activate([
      topAnchor.constraint(equalTo: superview.topAnchor, constant: padding),
      leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: padding),
      trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -padding),
      bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -padding)
    ])
  }
}
