//
//  ViewController.swift
//  CameraExercise
//
//  Created by mrJacob on 7/2/14.
//  Copyright (c) 2014 sushiGrass. All rights reserved.
//

import UIKit
import AVFoundation

class MainCameraViewController: UIViewController {
    
    @IBOutlet var previewView: PreviewView
    
    @lazy var session :AVCaptureSession = {
       return AVCaptureSession()
    }()
    
    @lazy var captureDevice :AVCaptureDevice = {
        let possibleDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as NSArray
        let frontCameraPredicate = NSPredicate(block: {(camera :AnyObject!, bindings :NSDictionary!) -> Bool in
            if camera is AVCaptureDevice {
                if let checkedCamera = camera as? AVCaptureDevice {
                    return checkedCamera.position == .Back
                }
            }
            return false
            })
        let captureDevice = possibleDevices.filteredArrayUsingPredicate(frontCameraPredicate)[0] as AVCaptureDevice
        if captureDevice.lockForConfiguration(nil) {
            captureDevice.focusMode = .Locked
        }
        return captureDevice
    }()
    
    @lazy var videoDeviceInput :AVCaptureDeviceInput = {
        var error = NSError()
        let captureDeviceInput = AVCaptureDeviceInput(device: self.captureDevice, error: nil)
        return captureDeviceInput
    }()
    
    @lazy var stillImageOutput :AVCaptureStillImageOutput = {
        let captureStillImageOutput = AVCaptureStillImageOutput()
        captureStillImageOutput.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
        return captureStillImageOutput
    }()
                            
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCamera()
        let rightPanGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "swipeGestureDidSwipe:")
        rightPanGestureRecognizer.direction = .Right
        self.view.addGestureRecognizer(rightPanGestureRecognizer)
        let leftPanGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "swipeGestureDidSwipe:")
        leftPanGestureRecognizer.direction = .Left
        self.view.addGestureRecognizer(leftPanGestureRecognizer)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func swipeGestureDidSwipe(swipeGesture: UISwipeGestureRecognizer) {
        if swipeGesture.state == .Ended {
            var focusAmount = self.captureDevice.lensPosition
            if swipeGesture.direction == .Right {
                if focusAmount < 0.89 {
                focusAmount += 0.1
                }
            }
            else {
                if focusAmount > 0.09 {
                focusAmount -= 0.1
                }
            }
            if self.captureDevice.lockForConfiguration(nil) {
                self.captureDevice.setFocusModeLockedWithLensPosition(focusAmount, completionHandler: nil)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        session.startRunning()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator!) {
        coordinator.animateAlongsideTransition(nil, completion: {(context :UIViewControllerTransitionCoordinatorContext!) in
            self.setPreviewLayerOrientation()
            })
    }
    
    func setupCamera() {
        
        previewView.session = session
        session.beginConfiguration()
        
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
            self.setPreviewLayerOrientation()
        }
        
        if session.canAddOutput(stillImageOutput) {
            session.addOutput(stillImageOutput)
        }
        
        session.commitConfiguration()
    }
    
    func setPreviewLayerOrientation () {
        dispatch_async(dispatch_get_main_queue(), {
            let previewViewLayer = self.previewView.layer as AVCaptureVideoPreviewLayer
            let orientation = AVCaptureVideoOrientation.fromRaw(self.interfaceOrientation.toRaw()) //can't force type to AVCaptureVideoDeviceOrientation…
            previewViewLayer.connection.videoOrientation = orientation!
            })
    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }


}

class PreviewView :UIView {
    override class func layerClass () -> AnyClass {
        return AVCaptureVideoPreviewLayer.self //weird
    }
    
    var session :AVCaptureSession {
        get {
            let layer = self.layer as AVCaptureVideoPreviewLayer
            return layer.session
        }
        set (newSession) {
            let layer = self.layer as AVCaptureVideoPreviewLayer
            layer.session = newSession
        }
    }
}

