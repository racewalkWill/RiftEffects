//
//  AVAssetExtension.swift
//  RiftEffects
//
//  Created by Will on 2/7/24.
//  from https://gist.github.com/mooshee/6b9e35c53047373568f5
//  and https://stackoverflow.com/questions/21887970/orientation-of-selected-video-in-uiimagepicker

import AVFoundation
import UIKit


extension AVAsset {

    func videoOrientation() async -> PGLDevicePosition {
        var orientation: UIInterfaceOrientation = .unknown
        var device: AVCaptureDevice.Position = .unspecified
        var myVideoTracks:[AVAssetTrack]?
        var t: CGAffineTransform = CGAffineTransformIdentity

        do {
             myVideoTracks =  try await loadTracks(withMediaType: .video)
        }
        catch {
//            Logger("no video tracks loaded for AVAsset #videoOrientation")
            /// return init values of .unknown and .unspecificed
                return PGLDevicePosition(orientation: orientation, device: device)
            }


        if let videoTrack = myVideoTracks?.first {

            do {
                 t = try await videoTrack.load(.preferredTransform)
            }
            catch {
//                fatalError("preferredTransform failed for AVAsset #videoOrientation")
                /// return init values of .unknown and .unspecificed
                return PGLDevicePosition(orientation: orientation, device: device)
            }

            if (t.a == 0 && t.b == 1.0 && t.d == 0) {
                orientation = .portrait

                if t.c == 1.0 {
                    device = .front
                } else if t.c == -1.0 {
                    device = .back
                }
            }
            else if (t.a == 0 && t.b == -1.0 && t.d == 0) {
                orientation = .portraitUpsideDown

                if t.c == -1.0 {
                    device = .front
                } else if t.c == 1.0 {
                    device = .back
                }
            }
            else if (t.a == 1.0 && t.b == 0 && t.c == 0) {
                orientation = .landscapeRight

                if t.d == -1.0 {
                    device = .front
                } else if t.d == 1.0 {
                    device = .back
                }
            }
            else if (t.a == -1.0 && t.b == 0 && t.c == 0) {
                orientation = .landscapeLeft

                if t.d == 1.0 {
                    device = .front
                } else if t.d == -1.0 {
                    device = .back
                }
            }
        }
        
        return PGLDevicePosition(orientation: orientation, device: device)
    }
}
