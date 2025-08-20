//
//  ChatMessageBarView.swift
//  Bloom
//
//  Created by Assistant on 2025-08-20.
//

@preconcurrency import UIKit
import SwiftUI
import SFSafeSymbols
import AudioToolbox
import PhotosUI
import DataContainer

protocol ChatMessageBarScrollDelegate: AnyObject {
  func chatMessageBarDidBeginEditing()
}

class ChatMessageBarView: UIView {

  // MARK: - Properties

  private let tabController: TabController
  weak var scrollDelegate: ChatMessageBarScrollDelegate?

  private let containerView = UIView()
  private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let cardContainerView = UIView()
  private let mainStackView = UIStackView()

  private let imageContextScrollView = UIScrollView()
  private let imageContextStackView = UIStackView()

  private let inputStackView = UIStackView()
  private let plusButton = UIButton(type: .system)
  private let textView = UITextView()
  private let actionButton = UIButton(type: .system)

  private let placeholderLabel = UILabel()

  private var textViewHeightConstraint: NSLayoutConstraint!
  private let minTextViewHeight: CGFloat = 24
  private let maxTextViewHeight: CGFloat = 120

  private var selectedImage: UIImage?
  private var keyboardHeight: CGFloat = 0

  // MARK: - Initialization

  init(tabController: TabController) {
    self.tabController = tabController
    super.init(frame: .zero)
    setupViews()
    setupConstraints()
    setupKeyboardObservers()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - Setup

  private func setupViews() {
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .clear

    // Container setup
    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.backgroundColor = .clear
    addSubview(containerView)

    // Blur effect setup
    blurEffectView.translatesAutoresizingMaskIntoConstraints = false
    blurEffectView.layer.cornerRadius = 40
    blurEffectView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    blurEffectView.clipsToBounds = true
    containerView.addSubview(blurEffectView)

    // Main stack view
    mainStackView.translatesAutoresizingMaskIntoConstraints = false
    mainStackView.axis = .vertical
    mainStackView.spacing = 0
    containerView.addSubview(mainStackView)

    // Image/context scroll view
    setupImageContextScrollView()

    // Input stack view
    setupInputStackView()

    // Update visibility
    updateImageContextVisibility()
  }

  private func setupImageContextScrollView() {
    imageContextScrollView.translatesAutoresizingMaskIntoConstraints = false
    imageContextScrollView.showsHorizontalScrollIndicator = false
    imageContextScrollView.isHidden = true

    imageContextStackView.translatesAutoresizingMaskIntoConstraints = false
    imageContextStackView.axis = .horizontal
    imageContextStackView.spacing = 8
    imageContextStackView.alignment = .center

    imageContextScrollView.addSubview(imageContextStackView)
    mainStackView.addArrangedSubview(imageContextScrollView)
  }

  private func setupInputStackView() {
    // Card container
    cardContainerView.translatesAutoresizingMaskIntoConstraints = false
    cardContainerView.backgroundColor = .systemBackground
    cardContainerView.layer.cornerRadius = 26
    cardContainerView.layer.shadowColor = UIColor.black.cgColor
    cardContainerView.layer.shadowOpacity = 0.05
    cardContainerView.layer.shadowOffset = CGSize(width: 0, height: 1)
    cardContainerView.layer.shadowRadius = 2

    // Input stack view
    inputStackView.translatesAutoresizingMaskIntoConstraints = false
    inputStackView.axis = .horizontal
    inputStackView.alignment = .bottom
    inputStackView.spacing = 8

    // Plus button setup
    setupPlusButton()

    // Text view setup
    setupTextView()

    // Action button setup
    setupActionButton()

    // Add to stack
    inputStackView.addArrangedSubview(plusButton)
    inputStackView.addArrangedSubview(textView)
    inputStackView.addArrangedSubview(actionButton)

    cardContainerView.addSubview(inputStackView)

    let cardWrapper = UIView()
    cardWrapper.translatesAutoresizingMaskIntoConstraints = false
    cardWrapper.addSubview(cardContainerView)

    mainStackView.addArrangedSubview(cardWrapper)

    // Card constraints
    NSLayoutConstraint.activate([
      cardContainerView.topAnchor.constraint(equalTo: cardWrapper.topAnchor),
      cardContainerView.leadingAnchor.constraint(equalTo: cardWrapper.leadingAnchor),
      cardContainerView.trailingAnchor.constraint(equalTo: cardWrapper.trailingAnchor),
      cardContainerView.bottomAnchor.constraint(equalTo: cardWrapper.bottomAnchor),

      inputStackView.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 12),
      inputStackView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor, constant: 12),
      inputStackView.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor, constant: -12),
      inputStackView.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor, constant: -12)
    ])
  }

  private func setupPlusButton() {
    plusButton.translatesAutoresizingMaskIntoConstraints = false
    
    // Configure the symbol with hierarchical rendering
    let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
    let image = UIImage(systemSymbol: .plusCircleFill, withConfiguration: config)
    plusButton.setImage(image, for: .normal)
    
    // Use tint color for the filled background
    plusButton.tintColor = .tintColor
    
    // Configure symbol rendering mode for hierarchical coloring (white foreground on tinted background)
    plusButton.imageView?.preferredSymbolConfiguration = UIImage.SymbolConfiguration(hierarchicalColor: .white)
    plusButton.configuration = UIButton.Configuration.plain()
    plusButton.configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(paletteColors: [.white, .tintColor])
    
    plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)

    NSLayoutConstraint.activate([
      plusButton.widthAnchor.constraint(equalToConstant: 24),
      plusButton.heightAnchor.constraint(equalToConstant: 24)
    ])
  }

  private func setupTextView() {
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.backgroundColor = .clear
    textView.font = .systemFont(ofSize: 17)
    textView.textColor = .label
    textView.textContainerInset = UIEdgeInsets.zero
    textView.textContainer.lineFragmentPadding = 0
    textView.isScrollEnabled = false
    textView.delegate = self
    textView.returnKeyType = .send

    // Placeholder
    placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
    placeholderLabel.text = "Message"
    placeholderLabel.font = .systemFont(ofSize: 17)
    placeholderLabel.textColor = .placeholderText
    textView.addSubview(placeholderLabel)

    textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: minTextViewHeight)
    textViewHeightConstraint.isActive = true

    NSLayoutConstraint.activate([
      placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor),
      placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
      placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor)
    ])
  }

  private func setupActionButton() {
    actionButton.translatesAutoresizingMaskIntoConstraints = false
    actionButton.configuration = UIButton.Configuration.plain()
    actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)

    NSLayoutConstraint.activate([
      actionButton.widthAnchor.constraint(equalToConstant: 24),
      actionButton.heightAnchor.constraint(equalToConstant: 24)
    ])

    updateActionButton()
  }

  private func setupConstraints() {
    NSLayoutConstraint.activate([
      // Container constraints
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

      // Blur effect constraints
      blurEffectView.topAnchor.constraint(equalTo: containerView.topAnchor),
      blurEffectView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      blurEffectView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      blurEffectView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

      // Main stack constraints
      mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
      mainStackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),

      // Image/context scroll view constraints
      imageContextScrollView.heightAnchor.constraint(equalToConstant: 60),
      imageContextStackView.topAnchor.constraint(equalTo: imageContextScrollView.topAnchor, constant: 4),
      imageContextStackView.leadingAnchor.constraint(equalTo: imageContextScrollView.leadingAnchor),
      imageContextStackView.trailingAnchor.constraint(equalTo: imageContextScrollView.trailingAnchor),
      imageContextStackView.bottomAnchor.constraint(equalTo: imageContextScrollView.bottomAnchor),
      imageContextStackView.heightAnchor.constraint(equalTo: imageContextScrollView.heightAnchor, constant: -4)
    ])
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
      selector: #selector(keyboardWillHide),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )
  }

  // MARK: - Actions

  @objc private func plusButtonTapped() {
    provideFeedback()
    presentImagePicker()
  }

  @objc private func actionButtonTapped() {
    provideFeedback()

    if textView.text.isEmpty {
      // Toggle keyboard
      if textView.isFirstResponder {
        textView.resignFirstResponder()
      } else {
        textView.becomeFirstResponder()
      }
    } else {
      // Send message
      Task {
        await submit()
      }
    }
  }

  // MARK: - Keyboard Handling

  @objc private func keyboardWillShow(_ notification: Notification) {
    guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
    keyboardHeight = keyboardFrame.height
    updateActionButton()
  }

  @objc private func keyboardWillHide(_ notification: Notification) {
    keyboardHeight = 0
    updateActionButton()
  }

  // MARK: - UI Updates

  private func updateActionButton() {
    let isEmpty = textView.text.isEmpty
    let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)

    if isEmpty {
      // Show keyboard toggle - text color on filled background
      let isKeyboardVisible = keyboardHeight > 0
      let symbolName: SFSymbol = isKeyboardVisible ? .chevronDownCircleFill : .chevronUpCircleFill
      let image = UIImage(systemSymbol: symbolName, withConfiguration: config)
      actionButton.setImage(image, for: .normal)
      
      // Use label color for chevron, secondary fill for background
      actionButton.tintColor = .tertiarySystemFill
      actionButton.configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(paletteColors: [.label, .tertiarySystemFill])
    } else {
      // Show send button - white arrow on tinted background
      let image = UIImage(systemSymbol: .arrowUpCircleFill, withConfiguration: config)
      actionButton.setImage(image, for: .normal)
      
      // Use tint color for background with white foreground
      actionButton.tintColor = .tintColor
      actionButton.configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(paletteColors: [.white, .tintColor])
    }
  }

  private func updateImageContextVisibility() {
    let hasContent = selectedImage != nil || !tabController.chatContexts.isEmpty

    UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
      self.imageContextScrollView.isHidden = !hasContent
      self.imageContextScrollView.alpha = hasContent ? 1 : 0
    }

    updateImageContextContent()
  }

  private func updateImageContextContent() {
    // Clear existing views
    imageContextStackView.arrangedSubviews.forEach { view in
      imageContextStackView.removeArrangedSubview(view)
      view.removeFromSuperview()
    }

    // Add image if present
    if let image = selectedImage {
      let imageView = createEditableImageView(image: image)
      imageContextStackView.addArrangedSubview(imageView)
    }

    // Add chat contexts
    for (index, context) in tabController.chatContexts.enumerated() {
      let contextView = createEditableContextView(context: context, index: index)
      imageContextStackView.addArrangedSubview(contextView)
    }
  }

  private func createEditableImageView(image: UIImage) -> UIView {
    let containerView = UIView()
    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.backgroundColor = .systemBackground
    containerView.layer.cornerRadius = 8
    containerView.layer.shadowColor = UIColor.black.cgColor
    containerView.layer.shadowOpacity = 0.1
    containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
    containerView.layer.shadowRadius = 4

    let imageView = UIImageView(image: image)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.layer.cornerRadius = 6
    imageView.clipsToBounds = true

    let removeButton = UIButton(type: .system)
    removeButton.translatesAutoresizingMaskIntoConstraints = false
    removeButton.setImage(UIImage(systemSymbol: .xmarkCircleFill), for: .normal)
    removeButton.tintColor = .systemRed
    removeButton.backgroundColor = .systemBackground
    removeButton.layer.cornerRadius = 10
    removeButton.addTarget(self, action: #selector(removeImageTapped), for: .touchUpInside)

    containerView.addSubview(imageView)
    containerView.addSubview(removeButton)

    NSLayoutConstraint.activate([
      containerView.widthAnchor.constraint(equalToConstant: 52),
      containerView.heightAnchor.constraint(equalToConstant: 52),

      imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
      imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
      imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
      imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4),

      removeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: -4),
      removeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 4),
      removeButton.widthAnchor.constraint(equalToConstant: 20),
      removeButton.heightAnchor.constraint(equalToConstant: 20)
    ])

    return containerView
  }

  private func createEditableContextView(context: ChatContext, index: Int) -> UIView {
    let containerView = UIView()
    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.backgroundColor = .systemBackground
    containerView.layer.cornerRadius = 8
    containerView.layer.shadowColor = UIColor.black.cgColor
    containerView.layer.shadowOpacity = 0.1
    containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
    containerView.layer.shadowRadius = 4
    containerView.tag = index // Store index for removal

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = context.title
    label.font = .systemFont(ofSize: 14, weight: .medium)
    label.textColor = .label
    label.numberOfLines = 2
    label.textAlignment = .center

    let removeButton = UIButton(type: .system)
    removeButton.translatesAutoresizingMaskIntoConstraints = false
    removeButton.setImage(UIImage(systemSymbol: .xmarkCircleFill), for: .normal)
    removeButton.tintColor = .systemRed
    removeButton.backgroundColor = .systemBackground
    removeButton.layer.cornerRadius = 10
    removeButton.tag = index
    removeButton.addTarget(self, action: #selector(removeContextTapped(_:)), for: .touchUpInside)

    containerView.addSubview(label)
    containerView.addSubview(removeButton)

    NSLayoutConstraint.activate([
      containerView.widthAnchor.constraint(equalToConstant: 100),
      containerView.heightAnchor.constraint(equalToConstant: 52),

      label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
      label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
      label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
      label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),

      removeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: -4),
      removeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 4),
      removeButton.widthAnchor.constraint(equalToConstant: 20),
      removeButton.heightAnchor.constraint(equalToConstant: 20)
    ])

    return containerView
  }

  @objc private func removeImageTapped() {
    selectedImage = nil
    updateImageContextVisibility()
  }

  @objc private func removeContextTapped(_ sender: UIButton) {
    let index = sender.tag
    if index < tabController.chatContexts.count {
      tabController.chatContexts.remove(at: index)
      updateImageContextVisibility()
    }
  }

  // MARK: - Image Picker

  private func presentImagePicker() {
    guard let parentViewController = findParentViewController() else { return }

    if #available(iOS 14.0, *) {
      var configuration = PHPickerConfiguration()
      configuration.filter = .images
      configuration.selectionLimit = 1

      let picker = PHPickerViewController(configuration: configuration)
      picker.delegate = self
      parentViewController.present(picker, animated: true)
    } else {
      let picker = UIImagePickerController()
      picker.sourceType = .photoLibrary
      picker.mediaTypes = ["public.image"]
      picker.delegate = self
      parentViewController.present(picker, animated: true)
    }
  }

  // MARK: - Message Submission

  private func submit() async {
    guard !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil else { return }

    provideFeedback()

    let textToSend = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    let imageToSend = selectedImage
    let chatContextsToSend = tabController.chatContexts

    // Clear inputs
    textView.text = ""
    selectedImage = nil
    tabController.chatContexts = []
    
    // Dismiss keyboard
    textView.resignFirstResponder()

    // Update UI
    updateActionButton()
    updateImageContextVisibility()
    updateTextViewHeight()

    do {
      try await ChatController.shared.send(
        message: textToSend,
        image: imageToSend,
        chatContexts: chatContextsToSend
      )
    } catch {
      // Show error
      await MainActor.run {
        showError(error)
      }
    }
  }

  private func showError(_ error: Error) {
    guard let parentViewController = findParentViewController() else { return }

    let alert = UIAlertController(
      title: "Error",
      message: error.localizedDescription,
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    parentViewController.present(alert, animated: true)
  }

  // MARK: - Helpers

  private func provideFeedback() {
    let impact = UIImpactFeedbackGenerator(style: .light)
    impact.impactOccurred()
  }
  
  func focusTextView() {
    textView.becomeFirstResponder()
  }

  private func findParentViewController() -> UIViewController? {
    var responder: UIResponder? = self
    while let nextResponder = responder?.next {
      if let viewController = nextResponder as? UIViewController {
        return viewController
      }
      responder = nextResponder
    }
    return nil
  }

  // MARK: - Intrinsic Content Size

  override var intrinsicContentSize: CGSize {
    // Calculate height based on text view content + padding
    let textViewHeight = textViewHeightConstraint?.constant ?? minTextViewHeight
    let imageContextHeight: CGFloat = (selectedImage != nil || !tabController.chatContexts.isEmpty) ? 60 : 0
    let totalHeight = textViewHeight + 32 + imageContextHeight // 32 = top/bottom padding + card padding

    return CGSize(width: UIView.noIntrinsicMetric, height: totalHeight)
  }
}

// MARK: - UITextViewDelegate

extension ChatMessageBarView: UITextViewDelegate {
  func textViewDidBeginEditing(_ textView: UITextView) {
    scrollDelegate?.chatMessageBarDidBeginEditing()
  }
  
  func textViewDidChange(_ textView: UITextView) {
    placeholderLabel.isHidden = !textView.text.isEmpty
    updateActionButton()
    updateTextViewHeight()

    // Handle newline submission
    if textView.text.hasSuffix("\n") {
      textView.text = String(textView.text.dropLast())
      Task {
        await submit()
      }
    }
  }

  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    if text == "\n" {
      Task {
        await submit()
      }
      return false
    }
    return true
  }

  private func updateTextViewHeight() {
    let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
    let height = max(minTextViewHeight, min(maxTextViewHeight, size.height))

    textViewHeightConstraint.constant = height
    textView.isScrollEnabled = height >= maxTextViewHeight

    invalidateIntrinsicContentSize()
  }
}

// MARK: - PHPickerViewControllerDelegate

@available(iOS 14.0, *)
extension ChatMessageBarView: PHPickerViewControllerDelegate {
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)

    guard let result = results.first else { return }

    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
      DispatchQueue.main.async {
        if let image = image as? UIImage {
          self?.selectedImage = image
          self?.updateImageContextVisibility()
        }
      }
    }
  }
}

// MARK: - UIImagePickerControllerDelegate

extension ChatMessageBarView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    picker.dismiss(animated: true)

    if let image = info[.originalImage] as? UIImage {
      selectedImage = image
      updateImageContextVisibility()
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
  }
}
