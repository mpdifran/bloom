//
//  Application+S3.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-14.
//

import Vapor
import S3Kit

extension Application {

    var s3: S3 {
        guard let accessKey = Environment.get("S3_ACCESS_KEY") else {
            fatalError("S3_ACCESS_KEY env var required")
        }
        guard let secretKey = Environment.get("S3_SECRET_KEY") else {
            fatalError("S3_SECRET_KEY env var required")
        }
        guard let bucket = Environment.get("S3_BUCKET_NAME") else {
            fatalError("S3_BUCKET_NAME env var required")
        }

        let config = S3Signer.Config(
            accessKey: accessKey,
            secretKey: secretKey,
            region: .init(
                name: Region.Name.usEast1,
                hostName: "127.0.0.1:9000",
                useTLS: false
            )
        )

        do {
            return try S3(
                defaultBucket: bucket,
                config: config
            )
        } catch {
            fatalError("Issue setting up S3: \(error.localizedDescription)")
        }
    }
}
