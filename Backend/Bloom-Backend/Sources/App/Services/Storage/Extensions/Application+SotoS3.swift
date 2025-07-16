//
//  Application+SotoS3.swift
//  Bloom-Backend
//
//  Created by Mike Welsh on 2024-11-24.
//

import SotoS3
import Vapor

extension Application {

  private struct AWSClientKey: StorageKey {
    typealias Value = AWSClient
  }

  private struct SotoS3AIKey: StorageKey {
    typealias Value = S3
  }

  var awsClient: AWSClient {
    if let client = storage[AWSClientKey.self] {
      return client
    }

    let client = AWSClient(httpClientProvider: .createNew)
    storage[AWSClientKey.self] = client

    return client
  }

  var sotoS3: S3 {
    if let s3 = storage[SotoS3AIKey.self] {
      return s3
    }

    let s3 = S3(client: awsClient)
    storage[SotoS3AIKey.self] = s3

    return s3
  }
  
  @Sendable func shutdownAWSClient() {
    // Shutdown AWS client if it exists
    if let client = storage[AWSClientKey.self] {
      try? client.syncShutdown()
    }
  }
}
