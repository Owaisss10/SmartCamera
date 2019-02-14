//
//  CameraViewController.swift
//  SmartCamera
//
//  Created by Apollo on 14/02/2019.
//  Copyright © 2019 Owais. All rights reserved.
//

import UIKit
import AVKit
import Vision

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - Variables
    
    let identifierLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Outlets
    
    // MARK: - View Loads

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = setupCamera() // Start Running the camera when view loads
    }
    

    // MARK: - Functions
    
    fileprivate func setupCamera() {
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high // for full screen view
        guard let captureDevice = AVCaptureDevice.default(for: .video)
            else { return }
        guard let input =
            try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let previewLayer =
            AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        setupIdentifierConfidenceLabel() // setting up the UILabel
    }
    
    fileprivate func setupIdentifierConfidenceLabel() {
        // adding it above view
        view.addSubview(identifierLabel)
        
        // setting constraints so that it works with every screen size
        identifierLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32).isActive = true
        identifierLabel.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        identifierLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        identifierLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    // MARK: - Camera Chief Function
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){
        guard let pixelBuffer: CVPixelBuffer =
            CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // DON'T FORGET !!!
        // Make sure to download & import the models in the project
        // Download Link: https://developer.apple.com/machine-learning/ scroll to the bottom and look for ResNet50
        
        guard let model = try? VNCoreMLModel(for: Resnet50().model)
            else { return }
        let request = VNCoreMLRequest(model: model)
        { (finishedReq, err) in
            guard let results =
                finishedReq.results as? [VNClassificationObservation]
                else { return }
            guard let firstObservation = results.first
                else { return }
            print(firstObservation.identifier, firstObservation.confidence)
            
            DispatchQueue.main.async {
                let confidenceRate = firstObservation.confidence * 100
                let objectName = firstObservation.identifier
                self.identifierLabel.text = "\(objectName) \(confidenceRate)"
            }
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}
