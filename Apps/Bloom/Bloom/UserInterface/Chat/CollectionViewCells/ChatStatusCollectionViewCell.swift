//
//  ChatStatusCollectionViewCell.swift
//  Bloom
//
//  Created by Assistant on 2025-06-02.
//

import UIKit
import SwiftUI
import ChatLayout

class ChatStatusCollectionViewCell: UICollectionViewCell {
  private var hostingController: UIHostingController<AnyView>?
  
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
  }
  
  func configure(with status: String) {
    let view = HStack {
      Text(status)
        .font(.subheadline)
        .bold()
        .foregroundStyle(.secondary)
        .fontDesign(.rounded)
        .multilineTextAlignment(.leading)
        .lineLimit(2)
        .contentTransition(.numericText())
      
      Spacer(minLength: 60)
    }
    .padding(.horizontal)
    
    updateHostingController(with: AnyView(view))
  }
  
  private func updateHostingController(with view: AnyView) {
    if let hostingController = hostingController {
      hostingController.rootView = view
      hostingController.view.invalidateIntrinsicContentSize()
    } else {
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
    
    // Force layout to calculate proper size
    setNeedsLayout()
    layoutIfNeeded()
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    hostingController?.rootView = AnyView(EmptyView())
  }
}

// MARK: - Size Calculation
extension ChatStatusCollectionViewCell {
  override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
    let targetSize = CGSize(width: layoutAttributes.frame.width, height: 0)
    
    // Force the hosting controller to calculate its size
    hostingController?.view.setNeedsLayout()
    hostingController?.view.layoutIfNeeded()
    
    let size = contentView.systemLayoutSizeFitting(
      targetSize,
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    
    var newFrame = layoutAttributes.frame
    newFrame.size.height = max(1, ceil(size.height))
    layoutAttributes.frame = newFrame
    
    return layoutAttributes
  }
}
