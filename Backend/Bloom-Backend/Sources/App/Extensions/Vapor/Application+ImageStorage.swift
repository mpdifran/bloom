//
//  Application+ImageStorage.swift
//  Bloom-Backend
//
//  Created by Haocen Jiang on 2025-02-13.
//

import Vapor
import OpenAIKit

extension Application {
  var imageStorage: ImageStorage {
    guard let bucket = Environment.get("S3_BUCKET_NAME") else {
      fatalError("S3_BUCKET_NAME env var required")
    }
    return S3Storage(
      bucketName: bucket,
      imageProcessing: ImageProcessor(),
      sotoS3: sotoS3,
      logger: logger,
      byteBufferAllocator: allocator
    )
  }
}
