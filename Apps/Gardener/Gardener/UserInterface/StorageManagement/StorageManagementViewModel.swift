//
//  StorageManagementViewModel.swift
//  Gardener
//
//  Created by Claude Code on 2025-11-30.
//

import AdminBloomModel
import AppKit
import BloomModel
import Foundation
import SwiftUI

@Observable
final class StorageManagementViewModel {

  private let networkStack = NetworkStack.shared

  // Storage stats
  var storageStats: StorageStats?
  var isLoadingStats = false
  var statsError: String?

  // Orphaned images
  var orphanedImagesInfo: GetOrphanedImagesResponse?
  var isLoadingOrphanedImages = false
  var orphanedImagesError: String?

  // Large images
  var largeImagesInfo: GetLargeImagesResponse?
  var isLoadingLargeImages = false
  var largeImagesError: String?
  var sizeThresholdKB: Int = 500

  // Image resizing
  var isResizingImages = false
  var resizeProgress: Double = 0.0
  var resizeStatus: String?

  // Operations
  var isDeletingOrphanedImages = false
  var deleteResult: String?

  init() {}

  // MARK: - Load Storage Stats

  @MainActor
  func loadStorageStats() async {
    isLoadingStats = true
    statsError = nil

    do {
      let response = try await networkStack.getStorageStats()
      storageStats = response.stats
    } catch {
      statsError = "Failed to load storage stats: \(error.localizedDescription)"
    }

    isLoadingStats = false
  }

  // MARK: - Orphaned Images

  @MainActor
  func findOrphanedImages() async {
    isLoadingOrphanedImages = true
    orphanedImagesError = nil

    do {
      let response = try await networkStack.getOrphanedImages()
      orphanedImagesInfo = response
    } catch {
      orphanedImagesError = "Failed to find orphaned images: \(error.localizedDescription)"
    }

    isLoadingOrphanedImages = false
  }

  @MainActor
  func deleteOrphanedImages() async {
    guard let orphanedInfo = orphanedImagesInfo, !orphanedInfo.orphanedImages.isEmpty else {
      deleteResult = "No orphaned images to delete"
      return
    }

    isDeletingOrphanedImages = true
    deleteResult = nil

    do {
      let imagePaths = orphanedInfo.orphanedImages.map { "\($0.path)/\($0.filename)" }
      let request = DeleteOrphanedImagesRequest(imagePaths: imagePaths)
      let response = try await networkStack.deleteOrphanedImages(request: request)

      if response.errors.isEmpty {
        deleteResult = "Successfully deleted \(response.deletedCount) orphaned images"
      } else {
        deleteResult = "Deleted \(response.deletedCount) images with \(response.errors.count) errors"
      }

      // Reload stats and orphaned images after deletion
      await loadStorageStats()
      await findOrphanedImages()
    } catch {
      deleteResult = "Failed to delete orphaned images: \(error.localizedDescription)"
    }

    isDeletingOrphanedImages = false
  }

  // MARK: - Large Images

  @MainActor
  func findLargeImages() async {
    isLoadingLargeImages = true
    largeImagesError = nil

    do {
      let thresholdBytes = Int64(sizeThresholdKB) * 1024
      let response = try await networkStack.getLargeImages(thresholdBytes: thresholdBytes)
      largeImagesInfo = response
    } catch {
      largeImagesError = "Failed to find large images: \(error.localizedDescription)"
    }

    isLoadingLargeImages = false
  }

  @MainActor
  func resizeLargeImages(maxWidth: Int = 800, quality: Double = 0.85) async {
    guard let largeInfo = largeImagesInfo, !largeInfo.largeImages.isEmpty else {
      resizeStatus = "No large images to resize"
      return
    }

    isResizingImages = true
    resizeProgress = 0.0
    resizeStatus = "Starting image resize..."

    let totalImages = largeInfo.largeImages.count
    var successCount = 0
    var failureCount = 0

    for (index, imageInfo) in largeInfo.largeImages.enumerated() {
      resizeStatus = "Processing \(index + 1) of \(totalImages): \(imageInfo.filename)"
      resizeProgress = Double(index) / Double(totalImages)

      do {
        try await processImage(imageInfo, maxWidth: maxWidth, quality: quality)
        successCount += 1
      } catch {
        print("Failed to resize \(imageInfo.filename): \(error)")
        failureCount += 1
      }
    }

    resizeProgress = 1.0
    resizeStatus = "Completed! Resized \(successCount) images (\(failureCount) failures)"

    // Reload stats after resizing
    await loadStorageStats()
    await findLargeImages()

    isResizingImages = false
  }

  // MARK: - Image Processing

  private func processImage(
    _ imageInfo: OrphanedImageInfo,
    maxWidth: Int,
    quality: Double
  ) async throws {
    // 1. Generate presigned URL for downloading
    let presignedURLRequest = GeneratePresignedURLRequest(
      filename: imageInfo.filename,
      path: imageInfo.path
    )
    let downloadURL = try await networkStack.generatePresignedURL(request: presignedURLRequest)

    // 2. Download the image
    let (imageData, response) = try await URLSession.shared.data(from: downloadURL)

    // 3. Resize the image
    guard let originalImage = NSImage(data: imageData) else {
      // Enhanced error message with debugging info
      var errorInfo: [String: Any] = [
        NSLocalizedDescriptionKey: "Failed to create image from data"
      ]
      if let httpResponse = response as? HTTPURLResponse {
        errorInfo["statusCode"] = httpResponse.statusCode
        errorInfo["contentType"] = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "unknown"
        errorInfo["dataSize"] = imageData.count
      }

      throw NSError(domain: "ImageProcessing", code: 1, userInfo: errorInfo)
    }

    guard let resizedImage = originalImage.resized(toMaxWidth: CGFloat(maxWidth)) else {
      throw NSError(domain: "ImageProcessing", code: 2, userInfo: [
        NSLocalizedDescriptionKey: "Failed to resize image"
      ])
    }

    // 4. Convert to JPEG data
    guard let jpegData = resizedImage.jpegData(compressionQuality: quality) else {
      throw NSError(domain: "ImageProcessing", code: 3, userInfo: [
        NSLocalizedDescriptionKey: "Failed to convert image to JPEG"
      ])
    }

    // 5. Determine file extension (keep as jpg for JPEG)
    let fileExtension = "jpg"

    // 6. Upload the resized image
    let replaceRequest = ReplaceImageRequest(
      filename: imageInfo.filename,
      path: imageInfo.path,
      imageData: ImageFile(data: jpegData, fileExtension: fileExtension)
    )
    try await networkStack.replaceImage(request: replaceRequest)
  }
}
