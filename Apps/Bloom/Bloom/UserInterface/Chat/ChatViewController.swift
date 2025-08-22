//
//  ChatViewController.swift
//  Bloom
//
//  Created by Assistant on 2025-08-20.
//

import UIKit
import SwiftUI
import ChatLayout
import DataContainer
import BloomFoundation
import DifferenceKit
import Combine
import SFSafeSymbols
import AppUI
import StoreKit

class ChatViewController: UICollectionViewController {

  // MARK: - Properties

  private let chatLayout: CollectionViewChatLayout
  private let viewModel = ChatViewModel()
  private let tabController: TabController
  private let themeController: ThemeController

  private var chatMessageBar: ChatMessageBarView!
  private var scrollToBottomButtonBottomConstraint: NSLayoutConstraint!

  private var cellModels: [ChatCellModel] = []
  private var isLoadingMore = false
  private var isAtBottom = true
  private var hasScrolledToBottomInitially = false
  private var previousBudMessageCount = 0

  private var cancellables = Set<AnyCancellable>()
  private var cellModelsTask: Task<Void, Never>?
  private var maintenanceTask: Task<Void, Never>?

  private lazy var scrollToBottomButton: UIButton = {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(UIImage(systemSymbol: .arrowDown), for: .normal)
    button.tintColor = .label
    button.backgroundColor = .systemBackground
    button.layer.cornerRadius = 16
    button.layer.shadowColor = UIColor.black.cgColor
    button.layer.shadowOpacity = 0.1
    button.layer.shadowOffset = CGSize(width: 0, height: 2)
    button.layer.shadowRadius = 4
    button.addTarget(self, action: #selector(scrollToBottomTapped), for: .touchUpInside)
    button.isHidden = true
    return button
  }()

  private var promptsHostingController: UIHostingController<AnyView>?

  // MARK: - Initialization

  init(tabController: TabController, themeController: ThemeController) {
    self.tabController = tabController
    self.themeController = themeController

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

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    setupNavigationBar()
    setupCollectionView()
    setupMessageBar()
    setupScrollToBottomButton()
    setupObservers()
    setupKeyboardObservers()
    updateContentInsets()

    // Scroll to bottom on initial appearance if there are messages
    if cellModels.isNotEmpty {
      scrollToBottom(animated: false)
    }

    // Start WebSocket maintenance
    maintenanceTask = Task {
      await viewModel.maintainWebSocketConnection()
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    // Focus the text view in the message bar
    chatMessageBar.focusTextView()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateContentInsets()
  }

  deinit {
    cellModelsTask?.cancel()
    maintenanceTask?.cancel()
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - Message Bar Setup
  
  private func setupMessageBar() {
    chatMessageBar = ChatMessageBarView(tabController: tabController)
    chatMessageBar.scrollDelegate = self
    chatMessageBar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(chatMessageBar)

    NSLayoutConstraint.activate([
      chatMessageBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      chatMessageBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      chatMessageBar.mainStackView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -16),
      chatMessageBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }
  
  private func updateContentInsets() {
    guard chatMessageBar != nil else { return }
    
    // Calculate the height of the message bar plus any keyboard
    let messageBarHeight = chatMessageBar.mainStackView.frame.height + 32 // Top and bottom padding included
    collectionView.contentInset.bottom = messageBarHeight + 16 // 16 for spacing
    collectionView.verticalScrollIndicatorInsets.bottom = messageBarHeight
  }

  // MARK: - Setup
  
  private func setupKeyboardObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillShow),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
  }
  
  @objc private func keyboardWillShow(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
          let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
      return
    }
    
    // Scroll to bottom with keyboard animation
    let animationOptions = UIView.AnimationOptions(rawValue: curve << 16)
    UIView.animate(withDuration: duration, delay: 0, options: [animationOptions, .beginFromCurrentState]) {
      if self.cellModels.isNotEmpty {
        let lastIndexPath = IndexPath(item: self.cellModels.count - 1, section: 0)
        self.collectionView.scrollToItem(at: lastIndexPath, at: .bottom, animated: false)
      }
    }
  }

  private func setupNavigationBar() {
    // Dismiss button (left) - modern iOS style with xmark
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: UIImage(systemSymbol: .xmark),
      style: .plain,
      target: self,
      action: #selector(doneTapped)
    )
//    navigationItem.leftBarButtonItem?.tintColor = .label

    // Bud image (center)
    let budImageView = UIImageView(image: .budCoach)
    budImageView.contentMode = .scaleAspectFit
    budImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      budImageView.widthAnchor.constraint(equalToConstant: 60),
      budImageView.heightAnchor.constraint(equalToConstant: 60)
    ])
    navigationItem.titleView = budImageView

    // Settings button (right)
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      image: UIImage(systemSymbol: .gear),
      style: .plain,
      target: self,
      action: #selector(settingsTapped)
    )
  }

  private func setupCollectionView() {
    collectionView.backgroundColor = .systemBackground
    collectionView.keyboardDismissMode = .interactive
    collectionView.alwaysBounceVertical = true
    collectionView.showsVerticalScrollIndicator = true
    collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)

    // Register cell types
    collectionView.register(ChatMessageCollectionViewCell.self, forCellWithReuseIdentifier: "ChatMessageCell")
    collectionView.register(ChatImageCollectionViewCell.self, forCellWithReuseIdentifier: "ChatImageCell")
    collectionView.register(ChatRichContentCollectionViewCell.self, forCellWithReuseIdentifier: "ChatRichContentCell")
    collectionView.register(ChatProcessedRichContentCollectionViewCell.self, forCellWithReuseIdentifier: "ChatProcessedRichContentCell")
    collectionView.register(ChatTypingIndicatorCollectionViewCell.self, forCellWithReuseIdentifier: "ChatTypingCell")
    collectionView.register(ChatStatusCollectionViewCell.self, forCellWithReuseIdentifier: "ChatStatusCell")
    collectionView.register(ChatPromptsCollectionViewCell.self, forCellWithReuseIdentifier: "ChatPromptsCell")
    collectionView.register(ChatUnknownContentCollectionViewCell.self, forCellWithReuseIdentifier: "ChatUnknownContentCollectionViewCell")
  }

  private func setupScrollToBottomButton() {
    view.addSubview(scrollToBottomButton)
    
    // Constrain to message bar so it moves with keyboard
    scrollToBottomButtonBottomConstraint = scrollToBottomButton.bottomAnchor.constraint(equalTo: chatMessageBar.topAnchor, constant: -8)
    
    NSLayoutConstraint.activate([
      scrollToBottomButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      scrollToBottomButtonBottomConstraint,
      scrollToBottomButton.widthAnchor.constraint(equalToConstant: 32),
      scrollToBottomButton.heightAnchor.constraint(equalToConstant: 32)
    ])
  }

  private func setupObservers() {
    // Simple polling observer - checking for changes every 100ms
    cellModelsTask = Task { [weak self] in
      var lastCellModels: [ChatCellModel] = []
      var lastError: Error?

      while !Task.isCancelled {
        await MainActor.run {
          guard let self = self else { return }

          // Check for cell model changes
          if self.viewModel.cellModels != lastCellModels {
            lastCellModels = self.viewModel.cellModels
            self.updateCellModels(self.viewModel.cellModels)
          }

          // Check for error changes
          if let error = self.viewModel.error, error.localizedDescription != lastError?.localizedDescription {
            lastError = error
            self.showError(error)
            // Clear the error after showing it
            self.viewModel.error = nil
          }
        }

        try? await Task.sleep(for: .milliseconds(100))
      }
    }
  }

  // MARK: - Actions

  @objc private func doneTapped() {
    chatMessageBar.resignTextFieldFocus()
    dismiss(animated: true)
  }

  @objc private func settingsTapped() {
    // Hide keyboard but keep input accessory view
    chatMessageBar.resignTextFieldFocus()
    
    let settingsView = ChatSettingsView()
      .environment(tabController)
      .environment(themeController)
      .tint(themeController.theme.color)

    let hostingController = UIHostingController(rootView: settingsView)
    hostingController.modalPresentationStyle = .pageSheet

    present(hostingController, animated: true)
  }

  @objc private func scrollToBottomTapped() {
    scrollToBottom(animated: true)
  }

  // MARK: - Data Updates

  private func updateCellModels(_ newModels: [ChatCellModel]) {
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

      // Hide prompts if we have messages
      updatePromptsVisibility()
      return
    }

    // Calculate the difference
    let changeset = StagedChangeset(source: oldModels, target: newModels)

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

    // Update prompts visibility
    updatePromptsVisibility()
    
    // Check for new Bud messages and potentially show rating prompt
    checkForNewBudMessage(newModels)
  }

  private func updatePromptsVisibility() {
    if cellModels.isEmpty {
      showPrompts()
    } else {
      hidePrompts()
    }
  }

  private func showPrompts() {
    guard promptsHostingController == nil else { return }

    let promptsView = ChatPromptsView()
      .environment(tabController)
      .environment(themeController)
      .tint(themeController.theme.color)

    let hostingController = UIHostingController(rootView: AnyView(promptsView))
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    hostingController.view.backgroundColor = .clear

    addChild(hostingController)
    view.addSubview(hostingController.view)

    NSLayoutConstraint.activate([
      hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      hostingController.view.heightAnchor.constraint(equalToConstant: 100)
    ])

    hostingController.didMove(toParent: self)
    promptsHostingController = hostingController
  }

  private func hidePrompts() {
    guard let hostingController = promptsHostingController else { return }

    hostingController.willMove(toParent: nil)
    hostingController.view.removeFromSuperview()
    hostingController.removeFromParent()
    promptsHostingController = nil
  }

  // MARK: - Scrolling

  func scrollToBottom(animated: Bool) {
    guard cellModels.isNotEmpty else { return }

    let lastIndexPath = IndexPath(item: cellModels.count - 1, section: 0)
    collectionView.scrollToItem(
      at: lastIndexPath,
      at: .bottom,
      animated: animated
    )
  }

  // MARK: - Error Handling

  private func checkForNewBudMessage(_ cellModels: [ChatCellModel]) {
    // Count non-user messages (messages from Bud)
    let currentBudMessageCount = cellModels.filter { cellModel in
      // Check if this is a message from Bud (not from current user)
      switch cellModel.contentType {
      case .text(_, _, let metadata), .richContent(_, _, let metadata):
        return metadata?.isCurrentUser == false
      case .image(_, _, let metadata):
        return metadata?.isCurrentUser == false
      default:
        return false
      }
    }.count
    
    // If we have more Bud messages than before, a new one arrived
    if currentBudMessageCount > previousBudMessageCount && previousBudMessageCount > 0 {
      // Record the event and potentially show rating prompt
      if RatingPromptTracker.shared.recordEvent() {
        // Request review using StoreKit
        if let windowScene = view.window?.windowScene {
          AppStore.requestReview(in: windowScene)
        }
      }
    }
    
    // Update the count for next time
    previousBudMessageCount = currentBudMessageCount
  }

  private func showError(_ error: Error) {
    let alert = UIAlertController(
      title: "Error",
      message: error.localizedDescription,
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}

// MARK: - UICollectionViewDataSource

extension ChatViewController {
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return cellModels.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let model = cellModels[indexPath.item]

    switch model.contentType {
    case .text(_, let content, let metadata):
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatMessageCell", for: indexPath) as! ChatMessageCollectionViewCell
      let isCurrentUser = metadata?.isCurrentUser ?? false
      let showReportButton = metadata?.showReportButton ?? false
      cell.configure(with: content, isCurrentUser: isCurrentUser, isLastInResponse: showReportButton, responseID: metadata?.responseID, requestID: metadata?.requestID)
      return cell

    case .image(_, let imageData, let metadata):
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatImageCell", for: indexPath) as! ChatImageCollectionViewCell
      let isCurrentUser = metadata?.isCurrentUser ?? false
      cell.configure(with: imageData, isCurrentUser: isCurrentUser)
      return cell

    case .richContent(let id, let content, let metadata):
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatProcessedRichContentCell", for: indexPath) as! ChatProcessedRichContentCollectionViewCell

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
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatTypingCell", for: indexPath) as! ChatTypingIndicatorCollectionViewCell
      return cell

    case .statusText(let status):
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatStatusCell", for: indexPath) as! ChatStatusCollectionViewCell
      cell.configure(with: status)
      return cell

    case .prompts:
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatPromptsCell", for: indexPath) as! ChatPromptsCollectionViewCell
      return cell
    }
  }
}

// MARK: - UICollectionViewDelegate

extension ChatViewController {
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    // Check if at bottom
    let contentHeight = scrollView.contentSize.height
    let scrollViewHeight = scrollView.bounds.height
    let scrollOffset = scrollView.contentOffset.y

    let newIsAtBottom = scrollOffset >= (contentHeight - scrollViewHeight - 50)
    if newIsAtBottom != isAtBottom {
      isAtBottom = newIsAtBottom

      // Show/hide scroll to bottom button
      UIView.animate(withDuration: 0.3) {
        self.scrollToBottomButton.isHidden = self.isAtBottom
        self.scrollToBottomButton.alpha = self.isAtBottom ? 0 : 1
      }
    }

    // Check if should load more (near top)
    if scrollOffset < 100 && !isLoadingMore && cellModels.isNotEmpty {
      isLoadingMore = true
      Task {
        await viewModel.loadMoreMessages()
        await MainActor.run {
          self.isLoadingMore = false
        }
      }
    }
  }
}

// MARK: - ChatLayoutDelegate

extension ChatViewController: ChatLayoutDelegate {
  func shouldPresentKeyboard(_ chatLayout: CollectionViewChatLayout) -> Bool {
    return false // We handle keyboard presentation ourselves
  }
}

// MARK: - ChatMessageBarScrollDelegate

extension ChatViewController: ChatMessageBarScrollDelegate {
  func chatMessageBarDidBeginEditing() {
    // The keyboard notification will handle scrolling
  }
}
