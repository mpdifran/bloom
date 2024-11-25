//
//  Request+SotoS3.swift
//  Bloom-Backend
//
//  Created by Mike Welsh on 2024-11-24.
//

import Vapor
import SotoS3

extension Request {

    private struct SotoS3AIKey: StorageKey {
        typealias Value = S3
    }

    var sotoS3: S3 {
        if let s3 = application.storage[SotoS3AIKey.self] {
            return s3
        } else {
            let s3 = application.sotoS3
            application.storage[SotoS3AIKey.self] = s3
            return s3
        }
    }
}
