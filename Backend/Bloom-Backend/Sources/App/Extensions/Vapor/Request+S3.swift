//
//  Request+S3.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-14.
//

import Vapor
@preconcurrency import S3Kit

extension Request {

    private struct S3AIKey: StorageKey {
        typealias Value = S3
    }

    var s3: S3 {
        if let s3 = application.storage[S3AIKey.self] {
            return s3
        } else {
            let s3 = application.s3
            application.storage[S3AIKey.self] = s3
            return s3
        }
    }
}
