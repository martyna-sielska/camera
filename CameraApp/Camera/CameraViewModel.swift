import AVFoundation
import CoreImage
import Photos
import UIKit

final class CameraViewModel: NSObject, ObservableObject {
  enum SessionState {
    case idle
    case running
    case failed
  }

  @Published var cameraPermission: PermissionState = .unknown
  @Published var photoPermission: PermissionState = .unknown
  @Published var currentDate: Date = Date()
  @Published var sessionState: SessionState = .idle

  let volumeListener = VolumeButtonListener()

  private let session = AVCaptureSession()
  private let sessionQueue = DispatchQueue(label: "camera.session")
  private let photoOutput = AVCapturePhotoOutput()
  private let ciContext = CIContext()

  private var isConfigured = false
  private var isCapturing = false
  private var dateTimer: Timer?

  override init() {
    super.init()
    volumeListener.onPress = { [weak self] in
      self?.capturePhoto()
    }
  }

  var captureSession: AVCaptureSession {
    session
  }

  func requestCameraOnly() {
    requestCameraPermission { _ in }
  }

  func startSession() {
    startDateTimer()
    requestCameraPermission { [weak self] cameraAuthorized in
      guard let self else { return }
      if cameraAuthorized {
        self.startSessionIfNeeded()
      }
    }
  }

  func stopSession() {
    dateTimer?.invalidate()
    dateTimer = nil
    sessionQueue.async { [weak self] in
      self?.session.stopRunning()
    }
    DispatchQueue.main.async {
      self.sessionState = .idle
    }
  }

  func capturePhoto() {
    guard !isCapturing else { return }
    guard cameraPermission == .authorized else { return }
    isCapturing = true

    let settings = AVCapturePhotoSettings()
    photoOutput.capturePhoto(with: settings, delegate: self)
  }

  private func requestCameraPermission(completion: @escaping (Bool) -> Void) {
    Permissions.requestCamera { [weak self] state in
      DispatchQueue.main.async {
        self?.cameraPermission = state
      }
      completion(state == .authorized)
    }
  }

  private func startSessionIfNeeded() {
    sessionQueue.async { [weak self] in
      guard let self else { return }
      self.configureIfNeeded()
      if !self.session.isRunning {
        self.session.startRunning()
      }
      DispatchQueue.main.async {
        self.sessionState = .running
      }
    }
  }

  private func configureIfNeeded() {
    guard !isConfigured else { return }
    isConfigured = true
    configureSession()
  }

  private func configureSession() {
    session.beginConfiguration()
    session.sessionPreset = .photo

    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
      session.commitConfiguration()
      return
    }

    do {
      let input = try AVCaptureDeviceInput(device: device)
      if session.canAddInput(input) {
        session.addInput(input)
      }
    } catch {
      session.commitConfiguration()
      return
    }

    if session.canAddOutput(photoOutput) {
      session.addOutput(photoOutput)
    }

    if let connection = photoOutput.connection(with: .video) {
      connection.videoOrientation = .landscapeRight
    }

    session.commitConfiguration()

    if device.isFocusModeSupported(.continuousAutoFocus) || device.isExposureModeSupported(.continuousAutoExposure) {
      do {
        try device.lockForConfiguration()
        if device.isFocusModeSupported(.continuousAutoFocus) {
          device.focusMode = .continuousAutoFocus
        }
        if device.isExposureModeSupported(.continuousAutoExposure) {
          device.exposureMode = .continuousAutoExposure
        }
        device.unlockForConfiguration()
      } catch {
        // Keep the session running even if focus/exposure cannot be changed.
      }
    }
  }

  private func startDateTimer() {
    dateTimer?.invalidate()
    dateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      self?.currentDate = Date()
    }
  }

  private func saveToPhotos(image: UIImage) {
    if photoPermission == .unknown {
      Permissions.requestPhotoLibraryAdd { [weak self] state in
        DispatchQueue.main.async {
          self?.photoPermission = state
          guard state == .authorized else {
            self?.isCapturing = false
            return
          }
          self?.saveToPhotos(image: image)
        }
      }
      return
    }

    guard photoPermission == .authorized else {
      DispatchQueue.main.async { [weak self] in
        self?.isCapturing = false
      }
      return
    }

    guard let data = image.jpegData(compressionQuality: 0.95) else {
      DispatchQueue.main.async { [weak self] in
        self?.isCapturing = false
      }
      return
    }

    PHPhotoLibrary.shared().performChanges({
      let request = PHAssetCreationRequest.forAsset()
      request.addResource(with: .photo, data: data, options: nil)
    }) { [weak self] _, _ in
      DispatchQueue.main.async {
        self?.isCapturing = false
      }
    }
  }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?
  ) {
    if error != nil {
      DispatchQueue.main.async { [weak self] in
        self?.isCapturing = false
      }
      return
    }

    guard let data = photo.fileDataRepresentation(),
          var image = CIImage(data: data) else {
      DispatchQueue.main.async { [weak self] in
        self?.isCapturing = false
      }
      return
    }

    if let orientationValue = photo.metadata[kCGImagePropertyOrientation as String] as? UInt32,
       let orientation = CGImagePropertyOrientation(rawValue: orientationValue) {
      image = image.oriented(orientation)
    } else {
      image = image.oriented(.right)
    }

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else { return }
      let filtered = CameraFilters.applyCapture(to: image)
      guard let cgImage = self.ciContext.createCGImage(filtered, from: filtered.extent) else {
        DispatchQueue.main.async {
          self.isCapturing = false
        }
        return
      }
      let uiImage = UIImage(cgImage: cgImage)
      let stamped = PixelDateRenderer.stamp(date: Date(), onto: uiImage)
      self.saveToPhotos(image: stamped)
    }
  }
}
