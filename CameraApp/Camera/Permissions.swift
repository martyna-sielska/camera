import AVFoundation
import Foundation
import Photos

enum PermissionState {
  case unknown
  case authorized
  case denied
}

enum Permissions {
  static func requestCamera(completion: @escaping (PermissionState) -> Void) {
    guard Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil else {
      completion(.denied)
      return
    }

    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .authorized:
      completion(.authorized)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        completion(granted ? .authorized : .denied)
      }
    default:
      completion(.denied)
    }
  }

  static func requestPhotoLibraryAdd(completion: @escaping (PermissionState) -> Void) {
    let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    switch status {
    case .authorized, .limited:
      completion(.authorized)
    case .notDetermined:
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
        let allowed = newStatus == .authorized || newStatus == .limited
        completion(allowed ? .authorized : .denied)
      }
    default:
      completion(.denied)
    }
  }
}
