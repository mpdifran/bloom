//
//  ImageStorage.swift
//  Bloom-Backend
//
//  Created by Mike Welsh on 2024-11-24.
//

import BloomModel
import Vapor
import SotoS3


/// Explicit enum for storage so that we limit the number of folders in our storage.
enum StoragePath: String {
  case nutritionLabel = "nutrition-label"
  case foodPackaging = "food-packaging"
}

protocol ImageStorage {

  /// Store the provided image file
  /// - Parameters:
  ///   - image: The image to store
  ///   - path: Where to store the image.
  func store(image: ImageFile, path: StoragePath) async throws -> ImageFileMetadata

  func generateImageURL(
    fileName: String,
    path: StoragePath,
    expiration: TimeAmount
  ) async throws -> URL?
  
  /// Retrieve image data from storage
  /// - Parameters:
  ///   - fileName: The name of the file to retrieve
  ///   - path: The storage path where the file is located
  func retrieveImage(fileName: String, path: StoragePath) async throws -> ImageFile?
}

struct S3Storage: ImageStorage {

  init(request: Request, bucketName: String) {
    self.request = request
    self.bucketName = bucketName
  }

  let request: Request
  let bucketName: String

  func store(image: ImageFile, path: StoragePath) async throws -> ImageFileMetadata {
    guard let imageType = request.imageProcessing.determineImageType(image.data) else {
      throw Abort(.badRequest, reason: "Unsupported image type")
    }
    
    let filename = "\(UUID().uuidString).\(imageType)"

    let putObjectRequest = S3.PutObjectRequest(
        body: .data(image.data, byteBufferAllocator: request.application.allocator),
        bucket: bucketName,
        key: "\(path)/\(filename)"
    )
    do {
        _ = try await request.sotoS3.putObject(putObjectRequest)
        request.logger.info("Saved image to S3: \(bucketName) - \(putObjectRequest.key)")
    } catch {
        request.logger.error("Failed to save content to S3: \(error)")
    }

    return ImageFileMetadata(filename: filename, data: image.data)
  }

  func generateImageURL(
    fileName: String,
    path: StoragePath,
    expiration: TimeAmount
  ) async throws -> URL? {
    let objectKey = "\(path)/\(fileName)"
    let region = request.sotoS3.region
    let url = URL(string: "https://\(bucketName).s3.\(region).amazonaws.com/\(objectKey)")!
    do {
      /// Reference: https://soto.codes/2020/12/presigned-urls.html
      let image = try await request.sotoS3.signURL(
        url: url,
        httpMethod: .GET,
        expires: expiration
      )
      request.logger.info("Successfully generated signed URL for S3: \(image)")
      return image
    } catch {
      request.logger.error("Failed to create S3 signed URL: \(error)")
      return nil
    }
  }

  func retrieveImage(fileName: String, path: StoragePath) async throws -> ImageFile? {
    let objectKey = "\(path)/\(fileName)"
    
    let getObjectRequest = S3.GetObjectRequest(
      bucket: bucketName,
      key: objectKey
    )
    
    do {
      let response = try await request.sotoS3.getObject(getObjectRequest)
      guard let data = response.body?.asData() else {
        request.logger.warning("No data in S3 response for: \(objectKey)")
        return nil
      }
      
      guard let fileExtension = fileName.split(separator: ".").last.map(String.init) else {
        request.logger.warning("Could not determine file extension for: \(fileName)")
        return nil
      }
      
      return ImageFile(data: data, fileExtension: fileExtension)
    } catch {
      request.logger.error("Failed to retrieve image from S3: \(error)")
      return nil
    }
  }
}
