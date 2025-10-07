//
//  ChatPromptsCollectionViewCell.swift
//  Bloom
//
//  Created by Assistant on 2025-06-02.
//

import UIKit
import SwiftUI
import ChatLayout

class ChatPromptsCollectionViewCell: UICollectionViewCell {
  private var hostingController: UIHostingController<ChatPromptsView>?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupUI() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    let view = ChatPromptsView()
    let controller = UIHostingController(rootView: view)
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
}

// MARK: - Size Calculation
extension ChatPromptsCollectionViewCell {
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