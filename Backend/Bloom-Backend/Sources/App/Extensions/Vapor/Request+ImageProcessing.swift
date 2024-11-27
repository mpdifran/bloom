//
//  Request+ImageProcessing.swift
//  Bloom-Backend
//
//  Created by Mike Welsh on 2024-11-26.
//

import Vapor

extension Request {

    var imageProcessing: ImageProcessing {
        return ImageProcessor()
    }
}
