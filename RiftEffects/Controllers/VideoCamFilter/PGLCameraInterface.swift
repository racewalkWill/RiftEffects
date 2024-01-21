//
//  PGLCameraInterface.swift
//  RiftEffects
//
//  Created by Will on 12/8/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//  based on Apple sample app AVCamFilter
//      class CameraViewController.swift


import UIKit
import AVFoundation
import CoreVideo
import Photos
import MobileCoreServices

/// connects to device's camera and provides frames to the PGLCameraViewFilter
class PGLCameraInterface: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
     var myCameraViewFilter: PGLVideoCameraFilter?

    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }

    private var setupResult: SessionSetupResult = .success

    private let session = AVCaptureSession()

    private var isSessionRunning = false

    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "SessionQueue", attributes: [], autoreleaseFrequency: .workItem)

    private var videoInput: AVCaptureDeviceInput!

    private let dataOutputQueue = DispatchQueue(label: "VideoDataQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

    private let videoDataOutput = AVCaptureVideoDataOutput()

    private var outputSynchronizer: AVCaptureDataOutputSynchronizer?

    private var renderingEnabled = true

    private let processingQueue = DispatchQueue(label: "photo processing queue", attributes: [], autoreleaseFrequency: .workItem)

    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: 
                [.builtInDualCamera, .builtInWideAngleCamera],
               mediaType: .video,
               position: .front)

     var statusBarOrientation: UIInterfaceOrientation = .landscapeLeft
    // orientation is set once. It does not change with device rotation..
    // see https://developer.apple.com/documentation/uikit/uidevice/1620055-isgeneratingdeviceorientationnot
    

    // MARK: - KVO and Notifications
    var sessionRunningContext = 0

    init(myCameraViewFilter: PGLVideoCameraFilter!) {
        self.myCameraViewFilter = myCameraViewFilter

    }

    func setUpInterface() {

        /*
         Setup the capture session.
         In general it is not safe to mutate an AVCaptureSession or any of its
         inputs, outputs, or connections from multiple threads at the same time.

         Don't do this on the main queue, because AVCaptureSession.startRunning()
         is a blocking call, which can take a long time. Dispatch session setup
         to the sessionQueue so as not to block the main queue, which keeps the UI responsive.
         */
        sessionQueue.async {
            self.configureSession()
        }

            // Check video authorization status, video access is required
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                    // The user has previously granted access to the camera
                break

            case .notDetermined:
                /*
                 The user has not yet been presented with the option to grant video access
                 Suspend the SessionQueue to delay session setup until the access request has completed
                 */
                sessionQueue.suspend()
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                    if !granted {
                        self.setupResult = .notAuthorized
                    }
                    self.sessionQueue.resume()
                })

            default:
                    // The user has previously denied access
                setupResult = .notAuthorized
        }


        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene

        {  statusBarOrientation = scene.interfaceOrientation }
        else { statusBarOrientation = .landscapeLeft }

        let initialThermalState = ProcessInfo.processInfo.thermalState
        if initialThermalState == .serious || initialThermalState == .critical {
//            showThermalState(state: initialThermalState)
        }



        sessionQueue.async {
            switch self.setupResult {
                case .success:
//                    self.addObservers()
//                    if let unwrappedVideoDataOutputConnection = self.videoDataOutput.connection(with: .video) {
//                        let videoDevicePosition = self.videoInput.device.position
//                    }

                    self.dataOutputQueue.async {
                        self.renderingEnabled = true
                    }

                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning


                case .notAuthorized:
                    DispatchQueue.main.async {
                        let message = NSLocalizedString("Rift-Effex doesn't have permission to use the camera.",
                                                        comment: "Alert message when the user has denied access to the camera")
                        let actions = [
                            UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                          style: .cancel,
                                          handler: nil),
                            UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                          style: .`default`,
                                          handler: { _ in
                                              UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                        options: [:],
                                                                        completionHandler: nil)
                                          })
                        ]

                        self.alert(title: "Rift-Effex", message: message, actions: actions)
                    }

                case .configurationFailed:
                    DispatchQueue.main.async {

                        let message = NSLocalizedString("Unable to capture media",
                                                        comment: "Alert message when something goes wrong during capture session configuration")

                        self.alert(title: "Rift-Effex", message: message ,
                                   actions: [UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                           style: .cancel,
                                                           handler: nil)])
                    }
            }
        }

    }

        // MARK: - Session Management

        // Call this on the SessionQueue
        private func configureSession() {
            if setupResult != .success {
                return
            }

            let defaultVideoDevice: AVCaptureDevice? = videoDeviceDiscoverySession.devices.first

            guard let videoDevice = defaultVideoDevice else {
                print("Could not find any video device")
                setupResult = .configurationFailed
                return
            }

            do {
                videoInput = try AVCaptureDeviceInput(device: videoDevice)
            } catch {
                print("Could not create video device input: \(error)")
                setupResult = .configurationFailed
                return
            }

            session.beginConfiguration()

            session.sessionPreset = AVCaptureSession.Preset.photo

            // Add a video input.
            guard session.canAddInput(videoInput) else {
                print("Could not add video device input to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            session.addInput(videoInput)

            // Add a video data output
            if session.canAddOutput(videoDataOutput) {
                session.addOutput(videoDataOutput)
                videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                videoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
            } else {
                print("Could not add video data output to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }

            outputSynchronizer = nil

            session.commitConfiguration()

        }

        // MARK: - Video Data Output Delegate

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            processVideo(sampleBuffer: sampleBuffer)
        }

        func processVideo(sampleBuffer: CMSampleBuffer) {
            if !renderingEnabled {
                return
            }

            guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            else  { return }
    //                ,
    //            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
    //                return
    //        }

            let finalVideoPixelBuffer = videoPixelBuffer

            let renderedCIImage = CIImage(cvImageBuffer: finalVideoPixelBuffer)

            myCameraViewFilter?.videoImageFrame = renderedCIImage

        }


    // MARK: UI State change
    func releaseOnViewDisappear() {
        dataOutputQueue.async {
            self.renderingEnabled = false
        }
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                self.removeObservers()
            }
        }

    }

 @objc   func didEnterBackground(notification: NSNotification) {
            // MARK: Release
        // Free up resources.
        dataOutputQueue.async {
            self.renderingEnabled = false
        }
    }

    @objc   func willEnterForground(notification: NSNotification) {
                dataOutputQueue.async {
                    self.renderingEnabled = true
                }
            }



    // MARK: userAlerts
    func alert(title: String, message: String, actions: [UIAlertAction]) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)

        actions.forEach {
            alertController.addAction($0)
        }

        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
        myAppDelegate.displayUser(alert: alertController)

    }

    func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(thermalStateChanged),
                                               name: ProcessInfo.thermalStateDidChangeNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionRuntimeError),
                                               name: NSNotification.Name.AVCaptureSessionRuntimeError,
                                               object: session)

        session.addObserver(self, forKeyPath: "running", options: NSKeyValueObservingOptions.new, context: &sessionRunningContext)

            // A session can run only when the app is full screen. It will be interrupted in a multi-app layout.
            // Add observers to handle these session interruptions and inform the user.
            // See AVCaptureSessionWasInterruptedNotification for other interruption reasons.

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionWasInterrupted),
                                               name: NSNotification.Name.AVCaptureSessionWasInterrupted,
                                               object: session)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterruptionEnded),
                                               name: NSNotification.Name.AVCaptureSessionInterruptionEnded,
                                               object: session)
    }

    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
//        session.removeObserver(self, forKeyPath: "running", context: &sessionRunningContext)
    }



    @objc  func sessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }

        let error = AVError(_nsError: errorValue)
        print("Capture session runtime error: \(error)")

        /*
         Automatically try to restart the session running if media services were
         reset and the last start running succeeded. Otherwise, enable the user
         to try to resume the session running.
         */
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                    }
                }
            }
    }

    @objc func sessionInterruptionEnded(notification: NSNotification) {

    }


//@IBAction 
    private func resumeInterruptedSession(_ sender: UIButton) {
        sessionQueue.async {
            /*
             The session might fail to start running. A failure to start the session running will be communicated via
             a session runtime error notification. To avoid repeatedly failing to start the session
             running, we only try to restart the session running in the session runtime error handler
             if we aren't trying to resume the session running.
             */
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
            if !self.session.isRunning {
                DispatchQueue.main.async {
                    let message = NSLocalizedString("Unable to resume", comment: "Alert message when unable to resume the session running")
                    let actions = [
                        UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                      style: .cancel,
                                      handler: nil)]
                    self.alert(title: "AVCamFilter", message: message, actions: actions)
                }
            }
        }
    }

    @objc func sessionWasInterrupted(notification: NSNotification) {
            // In iOS 9 and later, the userInfo dictionary contains information on why the session was interrupted.
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
           let reasonIntegerValue = userInfoValue.integerValue,
           let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")

            if reason == .videoDeviceInUseByAnotherClient {


            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                    // Simply fade-in a label to inform the user that the camera is unavailable.

            }
        }
    }

        // Use this opportunity to take corrective action to help cool the system down.
@objc func thermalStateChanged(notification: NSNotification) {
            if let processInfo = notification.object as? ProcessInfo {
                showThermalState(state: processInfo.thermalState)
            }
        }

        func showThermalState(state: ProcessInfo.ThermalState) {
            DispatchQueue.main.async {
                var thermalStateString = "UNKNOWN"
                if state == .nominal {
                    thermalStateString = "NOMINAL"
                } else if state == .fair {
                    thermalStateString = "FAIR"
                } else if state == .serious {
                    thermalStateString = "SERIOUS"
                } else if state == .critical {
                    thermalStateString = "CRITICAL"
                }

                let message = NSLocalizedString("Thermal state: \(thermalStateString)", comment: "Alert message when thermal state has changed")
                let actions = [
                    UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                  style: .cancel,
                                  handler: nil)]
                let alertController = UIAlertController(title: "Rift-Effex",
                                                        message: message,
                                                        preferredStyle: .alert)

                actions.forEach {
                    alertController.addAction($0)
                }
                let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
                myAppDelegate.displayUser(alert: alertController)

            }
        }

}
