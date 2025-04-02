//
//  Application+SotoS3.swift
//  Bloom-Backend
//
//  Created by Mike Welsh on 2024-11-24.
//

import SotoS3
import Vapor

extension Application {

  private struct SotoS3AIKey: StorageKey {
    typealias Value = S3
  }

  var sotoS3: S3 {
    if let s3 = storage[SotoS3AIKey.self] {
      return s3
    }

    let client = AWSClient(httpClientProvider: .createNew)

    let s3 = S3(client: client)
    storage[SotoS3AIKey.self] = s3

    return s3
  }
}
