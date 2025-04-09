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
  case chatImages = "chat-images"
}

protocol ImageStorage: Sendable {

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

  let bucketName: String
  let s3: S3
  let logger: Logger
  let allocator: ByteBufferAllocator

  init(
    bucketName: String,
    s3: S3,
    logger: Logger,
    allocator: ByteBufferAllocator
  ) {
    self.bucketName = bucketName
    self.s3 = s3
    self.logger = logger
    self.allocator = allocator
  }

  private let imageProcessing = ImageProcessor()

  func store(image: ImageFile, path: StoragePath) async throws -> ImageFileMetadata {
    guard let imageType = imageProcessing.determineImageType(image.data) else {
      throw Abort(.badRequest, reason: "Unsupported image type")
    }
    
    let filename = "\(UUID().uuidString).\(imageType)"

    let putObjectRequest = S3.PutObjectRequest(
        body: .data(image.data, byteBufferAllocator: allocator),
        bucket: bucketName,
        key: "\(path)/\(filename)"
    )
    do {
        _ = try await s3.putObject(putObjectRequest)
        logger.info("Saved image to S3: \(bucketName) - \(putObjectRequest.key)")
    } catch {
        logger.error("Failed to save content to S3: \(error)")
    }

    return ImageFileMetadata(filename: filename, data: image.data)
  }

  func generateImageURL(
    fileName: String,
    path: StoragePath,
    expiration: TimeAmount
  ) async throws -> URL? {
    let objectKey = "\(path)/\(fileName)"
    let region = s3.region
    let url = URL(string: "https://\(bucketName).s3.\(region).amazonaws.com/\(objectKey)")!
    do {
      /// Reference: https://soto.codes/2020/12/presigned-urls.html
      let image = try await s3.signURL(
        url: url,
        httpMethod: .GET,
        expires: expiration
      )
      logger.info("Successfully generated signed URL for S3: \(image)")
      return image
    } catch {
      logger.error("Failed to create S3 signed URL: \(error)")
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
      let response = try await s3.getObject(getObjectRequest)
      guard let data = response.body?.asData() else {
        logger.warning("No data in S3 response for: \(objectKey)")
        return nil
      }
      
      guard let fileExtension = fileName.split(separator: ".").last.map(String.init) else {
        logger.warning("Could not determine file extension for: \(fileName)")
        return nil
      }
      
      return ImageFile(data: data, fileExtension: fileExtension)
    } catch {
      logger.error("Failed to retrieve image from S3: \(error)")
      return nil
    }
  }
}
