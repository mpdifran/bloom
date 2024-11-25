//
//  ImageStorage.swift
//  Bloom-Backend
//
//  Created by Mike Welsh on 2024-11-24.
//

import BloomModel
import Vapor
import SotoS3

protocol ImageStorage {

  /// Store the provided image file
  func store(image: ImageFile) async throws -> ImageFileMetadata
}

struct S3Storage: ImageStorage {

  init(request: Request, bucketName: String) {
    self.request = request
    self.bucketName = bucketName
  }

  let request: Request
  let bucketName: String

  func store(image: BloomModel.ImageFile) async throws -> ImageFileMetadata {
    let filename = "\(UUID().uuidString).\(image.fileExtension)"

    let putObjectRequest = S3.PutObjectRequest(
        body: .data(image.data, byteBufferAllocator: request.application.allocator),
        bucket: bucketName,
        key: "testing/\(filename)"
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
