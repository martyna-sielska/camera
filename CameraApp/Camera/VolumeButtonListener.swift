import AVFoundation
import MediaPlayer
import UIKit

final class VolumeButtonListener: NSObject {
  var onPress: (() -> Void)?

  private var observation: NSKeyValueObservation?
  private var lastVolume: Float = 0.5
  private weak var volumeSlider: UISlider?
  private var isConfigured = false

  func attach(volumeView: MPVolumeView) {
    if let slider = volumeView.subviews.compactMap({ $0 as? UISlider }).first {
      volumeSlider = slider
      slider.value = 0.5
      lastVolume = slider.value
    }
  }

  func start() {
    guard !isConfigured else { return }
    isConfigured = true

    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.ambient, options: [.mixWithOthers])
    try? session.setActive(true)
    lastVolume = session.outputVolume

    observation = session.observe(\.outputVolume, options: [.new]) { [weak self] session, _ in
      guard let self else { return }
      let newVolume = session.outputVolume
      if abs(newVolume - self.lastVolume) < 0.001 { return }
      self.lastVolume = newVolume
      self.onPress?()
      self.resetVolume()
    }
  }

  func stop() {
    observation?.invalidate()
    observation = nil
    isConfigured = false
  }

  private func resetVolume() {
    guard let slider = volumeSlider else { return }
    DispatchQueue.main.async {
      slider.value = 0.5
    }
  }
}
