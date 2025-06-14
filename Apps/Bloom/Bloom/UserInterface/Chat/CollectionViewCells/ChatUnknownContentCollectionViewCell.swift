//
//  ChatUnknownContentCollectionViewCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-06-13.
//

import UIKit
import SwiftUI
import ChatLayout
import AppUI

class ChatUnknownContentCollectionViewCell: UICollectionViewCell {
  private var hostingController: UIHostingController<AnyView>?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension ChatUnknownContentCollectionViewCell {

  func configure(isLastInResponse: Bool, requestID: String?, responseID: String?) {

    let view = ChatUnknownContentCell(
      showReportButton: isLastInResponse,
      responseID: responseID,
      requestID: requestID
    )

    updateHostingController(with: view.asAny)
  }
}

private extension ChatUnknownContentCollectionViewCell {

  func setupUI() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    let view = ChatUnknownContentCell()
    let controller = UIHostingController(rootView: view.asAny)
    controller.view.translatesAutoresizingMaskIntoConstraints = false
    controller.view.backgroundColor = .clear

    contentView.addSubview(controller.view)

    NSLayoutConstraint.activate([
      controller.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      controller.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      controller.view.topAnchor.constraint(equalTo: contentView.topAnchor),
      controller.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
    ])

    self.hostingController = controller
  }

  private func updateHostingController(with view: AnyView) {
    if let hostingController = hostingController {
      hostingController.rootView = view
      hostingController.view.invalidateIntrinsicContentSize()
    } else {
      let controller = UIHostingController(rootView: view)
      controller.view.translatesAutoresizingMaskIntoConstraints = false
      controller.view.backgroundColor = .clear

      // Enable automatic sizing for the hosting controller
      controller.sizingOptions = [.intrinsicContentSize]

      contentView.addSubview(controller.view)

      NSLayoutConstraint.activate([
        controller.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        controller.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        controller.view.topAnchor.constraint(equalTo: contentView.topAnchor),
        controller.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
      ])

      self.hostingController = controller
    }

    // Force layout to calculate proper size
    hostingController?.view.invalidateIntrinsicContentSize()
    setNeedsLayout()
    layoutIfNeeded()
  }
}

// MARK: - Size Calculation
extension ChatUnknownContentCollectionViewCell {
  override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
    let targetSize = CGSize(width: layoutAttributes.frame.width, height: UIView.layoutFittingCompressedSize.height)

    let size = contentView.systemLayoutSizeFitting(
      targetSize,
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )

    var newFrame = layoutAttributes.frame
    newFrame.size.height = ceil(size.height)
    layoutAttributes.frame = newFrame

    return layoutAttributes
  }
}
