//
//  AdminStorageController.swift
//  Bloom-Backend
//
//  Created by Claude Code on 2025-11-30.
//

import AdminBloomModel
import BloomModel
import Fluent
import Foundation
import SotoS3
import Vapor

struct AdminStorageController { }

extension AdminStorageController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1", "admin") {
      $0.auth(using: AdminUserToken.self) {
        $0.group("storage") {
          $0.get("stats", use: getStorageStats)
          $0.get("orphaned-images", use: getOrphanedImages)
          $0.delete("orphaned-images", use: deleteOrphanedImages)
          $0.get("large-images", use: getLargeImages)
          $0.post("generate-presigned-url", use: generatePresignedURL)
          $0.post("replace-image", use: replaceImage)
        }
      }
    }
  }
}

private extension AdminStorageController {

  // MARK: - Get Storage Stats

  @Sendable
  func getStorageStats(request: Request) async throws -> GetStorageStatsResponse {
    let imageStorage = request.imageStorage

    async let nutritionLabelStats = getFolderStats(
      imageStorage: imageStorage,
      path: .nutritionLabel
    )
    async let foodPackagingStats = getFolderStats(
      imageStorage: imageStorage,
      path: .foodPackaging
    )
    async let chatImagesStats = getFolderStats(
      imageStorage: imageStorage,
      path: .chatImages
    )
    async let magicScannerStats = getFolderStats(
      imageStorage: imageStorage,
      path: .magicScanner
    )

    let stats = try await StorageStats(
      nutritionLabelStats: nutritionLabelStats,
      foodPackagingStats: foodPackagingStats,
      chatImagesStats: chatImagesStats,
      magicScannerStats: magicScannerStats
    )

    return GetStorageStatsResponse(stats: stats)
  }

  private func getFolderStats(
    imageStorage: ImageStorage,
    path: StoragePath
  ) async throws -> FolderStats {
    let objects = try await imageStorage.listObjects(path: path)

    let fileCount = objects.count
    let totalBytes = objects.reduce(0) { $0 + ($1.size ?? 0) }

    return FolderStats(fileCount: fileCount, totalBytes: totalBytes)
  }

  // MARK: - Get Orphaned Images

  @Sendable
  func getOrphanedImages(request: Request) async throws -> GetOrphanedImagesResponse {
    let imageStorage = request.imageStorage
    let db = request.db

    // Get all filenames from S3 for each path
    async let nutritionLabelFiles = imageStorage.listObjects(path: .nutritionLabel)
    async let foodPackagingFiles = imageStorage.listObjects(path: .foodPackaging)
    // Note: chat-images are not tracked in FoodItemRecord, so we can't determine orphans

    // Get all referenced filenames from database
    let foodRecords = try await FoodItemRecord.query(on: db).all()
    let referencedNutritionLabels = Set(foodRecords.compactMap { $0.nutritionLabelImage })
    let referencedPackagingImages = Set(foodRecords.compactMap { $0.packagingImage })

    var orphanedImages: [OrphanedImageInfo] = []

    // Find orphaned nutrition label images
    let nutritionFiles = try await nutritionLabelFiles
    for object in nutritionFiles {
      guard let filename = object.key?.split(separator: "/").last.map(String.init) else { continue }
      if !referencedNutritionLabels.contains(filename) {
        orphanedImages.append(OrphanedImageInfo(
          filename: filename,
          path: "nutrition-label",
          sizeBytes: object.size ?? 0,
          lastModified: object.lastModified
        ))
      }
    }

    // Find orphaned packaging images
    let packagingFiles = try await foodPackagingFiles
    for object in packagingFiles {
      guard let filename = object.key?.split(separator: "/").last.map(String.init) else { continue }
      if !referencedPackagingImages.contains(filename) {
        orphanedImages.append(OrphanedImageInfo(
          filename: filename,
          path: "food-packaging",
          sizeBytes: object.size ?? 0,
          lastModified: object.lastModified
        ))
      }
    }

    let totalCount = orphanedImages.count
    let totalBytes = orphanedImages.reduce(0) { $0 + $1.sizeBytes }

    return GetOrphanedImagesResponse(
      orphanedImages: orphanedImages,
      totalCount: totalCount,
      totalBytes: totalBytes
    )
  }

  // MARK: - Delete Orphaned Images

  @Sendable
  func deleteOrphanedImages(request: Request) async throws -> DeleteOrphanedImagesResponse {
    let requestBody = try request.content.decode(DeleteOrphanedImagesRequest.self)
    let imageStorage = request.imageStorage

    var deletedCount = 0
    var errors: [String] = []

    for imagePath in requestBody.imagePaths {
      let components = imagePath.split(separator: "/")
      guard components.count == 2 else {
        errors.append("Invalid path format: \(imagePath)")
        continue
      }

      let pathString = String(components[0])
      let filename = String(components[1])

      guard let storagePath = StoragePath(rawValue: pathString) else {
        errors.append("Invalid storage path: \(pathString)")
        continue
      }

      do {
        try await imageStorage.deleteImage(fileName: filename, path: storagePath)
        deletedCount += 1
      } catch {
        errors.append("Failed to delete \(imagePath): \(error.localizedDescription)")
      }
    }

    return DeleteOrphanedImagesResponse(deletedCount: deletedCount, errors: errors)
  }

  // MARK: - Get Large Images

  @Sendable
  func getLargeImages(request: Request) async throws -> GetLargeImagesResponse {
    let thresholdBytes: Int64
    if let queryThreshold = try? request.query.get(Int64.self, at: "thresholdBytes") {
      thresholdBytes = queryThreshold
    } else {
      thresholdBytes = 512_000 // Default: 500KB
    }

    let imageStorage = request.imageStorage

    // Get all objects from relevant paths
    async let nutritionLabelFiles = imageStorage.listObjects(path: .nutritionLabel)
    async let foodPackagingFiles = imageStorage.listObjects(path: .foodPackaging)
    async let chatImagesFiles = imageStorage.listObjects(path: .chatImages)

    var largeImages: [OrphanedImageInfo] = []

    // Filter nutrition label images
    let nutritionFiles = try await nutritionLabelFiles
    for object in nutritionFiles {
      guard let size = object.size, size > thresholdBytes else { continue }
      guard let filename = object.key?.split(separator: "/").last.map(String.init) else { continue }
      largeImages.append(OrphanedImageInfo(
        filename: filename,
        path: "nutrition-label",
        sizeBytes: size,
        lastModified: object.lastModified
      ))
    }

    // Filter packaging images
    let packagingFiles = try await foodPackagingFiles
    for object in packagingFiles {
      guard let size = object.size, size > thresholdBytes else { continue }
      guard let filename = object.key?.split(separator: "/").last.map(String.init) else { continue }
      largeImages.append(OrphanedImageInfo(
        filename: filename,
        path: "food-packaging",
        sizeBytes: size,
        lastModified: object.lastModified
      ))
    }

    // Filter chat images
    let chatFiles = try await chatImagesFiles
    for object in chatFiles {
      guard let size = object.size, size > thresholdBytes else { continue }
      guard let filename = object.key?.split(separator: "/").last.map(String.init) else { continue }
      largeImages.append(OrphanedImageInfo(
        filename: filename,
        path: "chat-images",
        sizeBytes: size,
        lastModified: object.lastModified
      ))
    }

    let totalCount = largeImages.count
    let totalBytes = largeImages.reduce(0) { $0 + $1.sizeBytes }

    return GetLargeImagesResponse(
      largeImages: largeImages,
      totalCount: totalCount,
      totalBytes: totalBytes
    )
  }

  // MARK: - Generate Presigned URL

  @Sendable
  func generatePresignedURL(request: Request) async throws -> GeneratePresignedURLResponse {
    let requestBody = try request.content.decode(GeneratePresignedURLRequest.self)
    let imageStorage = request.imageStorage

    guard let storagePath = StoragePath(rawValue: requestBody.path) else {
      throw Abort(.badRequest, reason: "Invalid storage path: \(requestBody.path)")
    }

    guard let url = try await imageStorage.generateImageURL(
      fileName: requestBody.filename,
      path: storagePath,
      expiration: .hours(2)
    ) else {
      throw Abort(.internalServerError, reason: "Failed to generate presigned URL")
    }

    return GeneratePresignedURLResponse(url: url)
  }

  // MARK: - Replace Image

  @Sendable
  func replaceImage(request: Request) async throws -> HTTPStatus {
    struct ReplaceImageRequest: Codable {
      let filename: String
      let path: String
      let imageData: ImageFile
    }

    let requestBody = try request.content.decode(ReplaceImageRequest.self)
    let imageStorage = request.imageStorage

    guard let storagePath = StoragePath(rawValue: requestBody.path) else {
      throw Abort(.badRequest, reason: "Invalid storage path: \(requestBody.path)")
    }

    // Replace the image with new data
    try await imageStorage.replaceImage(
      fileName: requestBody.filename,
      path: storagePath,
      imageData: requestBody.imageData.data
    )

    return .ok
  }
}
