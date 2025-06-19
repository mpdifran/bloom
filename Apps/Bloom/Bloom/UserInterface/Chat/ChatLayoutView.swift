//
//  ChatLayoutView.swift
//  Bloom
//
//  Created by Assistant on 2025-06-02.
//

import SwiftUI
import UIKit
import ChatLayout
import DataContainer
import BloomFoundation
import DifferenceKit

struct ChatLayoutView: UIViewControllerRepresentable {
  @Binding var cellModels: [ChatCellModel]
  @Binding var scrollToBottomTrigger: Bool
  let onLoadMore: () async -> Void
  let onIsAtBottomChanged: (Bool) -> Void
  
  func makeUIViewController(context: Context) -> ChatLayoutViewController {
    let viewController = ChatLayoutViewController()
    viewController.onLoadMore = onLoadMore
    viewController.onIsAtBottomChanged = onIsAtBottomChanged
    return viewController
  }
  
  func updateUIViewController(_ uiViewController: ChatLayoutViewController, context: Context) {
    uiViewController.updateCellModels(cellModels)
    
    if scrollToBottomTrigger {
      uiViewController.scrollToBottom(animated: true)
      DispatchQueue.main.async {
        scrollToBottomTrigger = false
      }
    }
  }
}

class ChatLayoutViewController: UICollectionViewController {
  private var chatLayout: CollectionViewChatLayout!
  private var cellModels: [ChatCellModel] = []
  
  var onLoadMore: (() async -> Void)?
  var onIsAtBottomChanged: ((Bool) -> Void)?
  
  private var isLoadingMore = false
  private var isAtBottom = true
  private var hasScrolledToBottomInitially = false
  
  init() {
    chatLayout = CollectionViewChatLayout()
    chatLayout.settings.estimatedItemSize = CGSize(width: UIScreen.main.bounds.width, height: 100)
    chatLayout.settings.interItemSpacing = 6
    chatLayout.keepContentOffsetAtBottomOnBatchUpdates = true
    
    super.init(collectionViewLayout: chatLayout)
    
    chatLayout.delegate = self
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupCollectionView()
    setupKeyboardObservers()

    // Scroll to bottom on initial appearance
    if cellModels.isNotEmpty {
      scrollToBottom(animated: false)
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  private func setupCollectionView() {
    collectionView.backgroundColor = .clear
    collectionView.keyboardDismissMode = .interactive
    collectionView.alwaysBounceVertical = true
    collectionView.showsVerticalScrollIndicator = true
    collectionView.contentInsetAdjustmentBehavior = .automatic
  }
  
  private func setupKeyboardObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillShow),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardDidShow),
      name: UIResponder.keyboardDidShowNotification,
      object: nil
    )
  }
  
  @objc private func keyboardWillShow(_ notification: Notification) {
    scrollToBottom(animated: true)
  }
  
  @objc private func keyboardDidShow(_ notification: Notification) {
    scrollToBottom(animated: true)
  }
  
  func updateCellModels(_ newModels: [ChatCellModel]) {
    let oldModels = cellModels
    
    guard oldModels != newModels else { return }
    
    // Initial load
    if !hasScrolledToBottomInitially && newModels.isNotEmpty {
      cellModels = newModels
      collectionView.reloadData()
      hasScrolledToBottomInitially = true
      
      // Ensure layout is complete before scrolling
      collectionView.layoutIfNeeded()
      scrollToBottom(animated: false)
      return
    }

    print("Old Models:\n\(oldModels.map { $0.id })")
    print("New Models:\n\(newModels.map { $0.id })")

    // Calculate the difference
    let changeset = StagedChangeset(source: oldModels, target: newModels)

    print("Changeset")
    for set in changeset {
      let inserted = set.elementInserted.map { $0.element }
      let deleted = set.elementDeleted.map { $0.element }
      let updated = set.elementUpdated.map { $0.element }
      let moved = set.elementMoved.map { "\($0.source.element) -> \($0.target.element)" }

      print("Insert: \(inserted)\nDeleted:\(deleted)\nUpdated:\(updated)\nMoved:\(moved)\n")
    }

    // Apply the changes with batch updates
    collectionView.reload(using: changeset, interrupt: { $0.changeCount > 100 }) { [weak self] newModels in
      self?.cellModels = newModels
    }
    
    // Force reload cells that have text messages (for streaming updates)
    for (index, model) in newModels.enumerated() {
      if case .text(_, let content, let metadata) = model.contentType, metadata == nil {
        let indexPath = IndexPath(item: index, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? ChatMessageCollectionViewCell {
          cell.configure(with: content, isCurrentUser: false, isLastInResponse: false)
        }
      }
    }
  }
  
  
  func scrollToBottom(animated: Bool) {
    guard cellModels.isNotEmpty else { return }
    
    let lastIndexPath = IndexPath(item: cellModels.count - 1, section: 0)
    collectionView.scrollToItem(at: lastIndexPath, at: .bottom, animated: animated)
  }
  
}

// MARK: - UICollectionViewDataSource
extension ChatLayoutViewController {
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return cellModels.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let model = cellModels[indexPath.item]
    
    switch model.contentType {
    case .text(let id, let content, let metadata):
      let cell = collectionView.autoDequeueCell(ofType: ChatMessageCollectionViewCell.self, for: indexPath)
      let isCurrentUser = metadata?.isCurrentUser ?? false
      let showReportButton = metadata?.showReportButton ?? false
      cell.configure(with: content, isCurrentUser: isCurrentUser, isLastInResponse: showReportButton, responseID: metadata?.responseID, requestID: metadata?.requestID)
      return cell
      
    case .image(let id, let imageData, let metadata):
      let cell = collectionView.autoDequeueCell(ofType: ChatImageCollectionViewCell.self, for: indexPath)
      let isCurrentUser = metadata?.isCurrentUser ?? false
      cell.configure(with: imageData, isCurrentUser: isCurrentUser)
      return cell
      
    case .richContent(let id, let content, let metadata):
      let cell = collectionView.autoDequeueCell(ofType: ChatProcessedRichContentCollectionViewCell.self, for: indexPath)
      let showReportButton = metadata?.showReportButton ?? false

      cell.configure(
        chatMessageID: id,
        content: content,
        hasPerformedAction: metadata?.hasPerformedAction ?? false,
        dbID: metadata?.dbID,
        showReportButton: showReportButton,
        responseID: metadata?.responseID,
        requestID: metadata?.requestID
      )
      return cell
      
    case .typingIndicator:
      let cell = collectionView.autoDequeueCell(ofType: ChatTypingIndicatorCollectionViewCell.self, for: indexPath)
      return cell
      
    case .statusText(let status):
      let cell = collectionView.autoDequeueCell(ofType: ChatStatusCollectionViewCell.self, for: indexPath)
      cell.configure(with: status)
      return cell
      
    case .prompts:
      let cell = collectionView.autoDequeueCell(ofType: ChatPromptsCollectionViewCell.self, for: indexPath)
      return cell
    }
  }
}

// MARK: - UICollectionViewDelegate
extension ChatLayoutViewController {
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    // Check if at bottom
    let contentHeight = scrollView.contentSize.height
    let scrollViewHeight = scrollView.bounds.height
    let scrollOffset = scrollView.contentOffset.y
    
    let newIsAtBottom = scrollOffset >= (contentHeight - scrollViewHeight - 50)
    if newIsAtBottom != isAtBottom {
      isAtBottom = newIsAtBottom
      onIsAtBottomChanged?(isAtBottom)
    }
    
    // Check if should load more (near top)
    if scrollOffset < 100 && !isLoadingMore && cellModels.isNotEmpty {
      isLoadingMore = true
      Task {
        await onLoadMore?()
        await MainActor.run {
          self.isLoadingMore = false
        }
      }
    }
  }
}

// MARK: - ChatLayoutDelegate
extension ChatLayoutViewController: ChatLayoutDelegate {
  func shouldPresentKeyboard(_ chatLayout: CollectionViewChatLayout) -> Bool {
    return false // We handle keyboard presentation in SwiftUI
  }
}
