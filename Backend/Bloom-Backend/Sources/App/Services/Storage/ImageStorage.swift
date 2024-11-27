//
//  ImageStorage.swift
//  Bloom-Backend
//
//  Created by Mike Welsh on 2024-11-24.
//

import BloomModel
import Vapor
import SotoS3


/// Explicit enum for storage so that we limit the number of folders in our storage.
enum StoragePath: String {
  case nutritionLabel = "nutrition-label"
  case foodPackaging = "food-packaging"
}

protocol ImageStorage {

  /// Store the provided image file
  /// - Parameters:
  ///   - image: The image to store
  ///   - path: Where to store the image.
  func store(image: ImageFile, path: StoragePath) async throws -> ImageFileMetadata
}

struct S3Storage: ImageStorage {

  init(request: Request, bucketName: String) {
    self.request = request
    self.bucketName = bucketName
  }

  let request: Request
  let bucketName: String

  func store(image: ImageFile, path: StoragePath) async throws -> ImageFileMetadata {
    guard let imageType = request.imageProcessing.determineImageType(image.data) else {
      throw Abort(.badRequest, reason: "Unsupported image type")
    }
    
    let filename = "\(UUID().uuidString).\(imageType)"

    let putObjectRequest = S3.PutObjectRequest(
        body: .data(image.data, byteBufferAllocator: request.application.allocator),
        bucket: bucketName,
        key: "\(path)/\(filename)"
    )
    do {
        _ = try await request.sotoS3.putObject(putObjectRequest)
        request.logger.info("Saved image to S3: \(bucketName) - \(putObjectRequest.key)")
    } catch {
        request.logger.error("Failed to save content to S3: \(error)")
    }

    return ImageFileMetadata(filename: filename, data: image.data)
  }
}
