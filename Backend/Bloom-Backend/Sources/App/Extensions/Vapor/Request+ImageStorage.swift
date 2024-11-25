//
//  Request+ImageStorage.swift
//  Bloom-Backend
//
//  Created by Mike Welsh on 2024-11-24.
//

import Vapor

extension Request {
    var imageStorage: ImageStorage {
        return S3Storage(request: self)
    }
}
