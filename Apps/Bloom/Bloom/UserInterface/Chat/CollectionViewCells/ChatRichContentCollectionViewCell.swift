//
//  ChatRichContentCollectionViewCell.swift
//  Bloom
//
//  Created by Assistant on 2025-06-02.
//

import UIKit
import SwiftUI
import ChatLayout
import DataContainer

class ChatRichContentCollectionViewCell: UICollectionViewCell {
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
  
  func configure(with chatMessage: ChatMessageDTO, isLastInResponse: Bool = false) {
    guard case .richContent(let data) = chatMessage.content else { return }
    
    let view = ChatRichContentWrapperCell(
      chatMessageID: chatMessage.id,
      data: data,
      hasPerformedAction: chatMessage.hasPerformedAction,
      dbID: chatMessage.dbID,
      showReportButton: isLastInResponse,
      responseID: chatMessage.responseID,
      requestID: chatMessage.requestID
    )
    
    updateHostingController(with: AnyView(view))
  }
  
  func configure(with inProgressMessage: ChatController.InProgressMessage) {
    guard let data = inProgressMessage.data else { return }
    
    let view = ChatRichContentWrapperCell(
      chatMessageID: "",
      data: data,
      hasPerformedAction: false,
      dbID: nil,
      showReportButton: false,
      responseID: nil,
      requestID: nil
    )
    
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
  
  override func prepareForReuse() {
    super.prepareForReuse()
    hostingController?.rootView = AnyView(EmptyView())
  }
  
  override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
    setNeedsLayout()
    layoutIfNeeded()
    
    var calculatedHeight: CGFloat
    
    // Try to get intrinsic content size from hosting controller first
    if let hostingController = hostingController {
      let targetSize = CGSize(width: layoutAttributes.frame.width, height: UIView.noIntrinsicMetric)
      let intrinsicSize = hostingController.sizeThatFits(in: targetSize)
      calculatedHeight = intrinsicSize.height
      
      // Fallback to system layout sizing if intrinsic size is not valid
      if calculatedHeight <= 0 {
        let systemSize = contentView.systemLayoutSizeFitting(
          CGSize(width: layoutAttributes.frame.width, height: 0),
          withHorizontalFittingPriority: .required,
          verticalFittingPriority: .fittingSizeLevel
        )
        calculatedHeight = systemSize.height
      }
    } else {
      // Fallback when no hosting controller
      let targetSize = CGSize(width: layoutAttributes.frame.width, height: 0)
      let size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
      calculatedHeight = size.height
    }
    
    var frame = layoutAttributes.frame
    frame.size.height = ceil(max(calculatedHeight, 44)) // Minimum height of 44
    layoutAttributes.frame = frame
    
    return layoutAttributes
  }
}