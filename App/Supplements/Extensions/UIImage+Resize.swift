//
//  UIImage+Resize.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-19.
//

import UIKit

extension UIImage {
    func resized(toWidth newWidth: CGFloat) -> UIImage? {

        let aspectRatio = size.height / size.width
        let newHeight = newWidth * aspectRatio
        let newSize = CGSize(width: newWidth, height: newHeight)

        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: .zero, size: newSize))

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
