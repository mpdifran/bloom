//
//  Request+ImageStorage.swift
//  Bloom-Backend
//
//  Created by Mike Welsh on 2024-11-24.
//

import Vapor

extension Request {

    var imageStorage: ImageStorage {
        guard let bucket = Environment.get("S3_BUCKET_NAME") else {
            fatalError("S3_BUCKET_NAME env var required")
        }
        return S3Storage(request: self, bucketName: bucket)
    }
}
