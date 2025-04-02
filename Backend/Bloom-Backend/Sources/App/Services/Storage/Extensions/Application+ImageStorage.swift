//
//  Application+ImageStorage.swift
//  Bloom-Backend
//
//  Created by Mike Welsh on 2024-11-24.
//

import Vapor

extension Application {

  private struct S3StorageKey: StorageKey {
    typealias Value = S3Storage
  }

  var imageStorage: ImageStorage {
    if let imageStorage = storage[S3StorageKey.self] {
      return imageStorage
    }

    guard let bucket = Environment.get("S3_BUCKET_NAME") else {
      fatalError("S3_BUCKET_NAME env var required")
    }

    let imageStorage = S3Storage(
      bucketName: bucket,
      s3: sotoS3,
      logger: logger,
      allocator: allocator
    )
    storage[S3StorageKey.self] = imageStorage

    return imageStorage
  }
}
