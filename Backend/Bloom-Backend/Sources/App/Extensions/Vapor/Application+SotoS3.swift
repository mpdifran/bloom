//
//  Application+SotoS3.swift
//  Bloom-Backend
//
//  Created by Mike Welsh on 2024-11-24.
//

import SotoS3
import Vapor

extension Application {

    var sotoS3: S3 {
        let client = AWSClient(httpClientProvider: .createNew)
        let s3 = S3(client: client)
        return s3
    }
}
