//
//  Request+SotoS3.swift
//  Bloom-Backend
//
//  Created by Mike Welsh on 2024-11-24.
//

import Vapor
import SotoS3

extension Request {

  var sotoS3: S3 {
    application.sotoS3
  }
}
