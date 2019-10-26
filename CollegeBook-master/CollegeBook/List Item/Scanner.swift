//
//  Scanner.swift
//  CollegeBook
//
//  Created by Jin Kim on 9/16/19.
//  Copyright © 2019 Avi Khemani. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class Scanner: NSObject
{
    private var viewController: UIViewController
    private var captureSession : AVCaptureSession?
    private var codeOutputHandler: (_ code: String) -> Void
    private var subLayer: AVCaptureVideoPreviewLayer
    
    init(withViewController viewController: UIViewController, view: UIView, codeOutputHandler: @escaping (String) -> Void) {
        self.viewController = viewController
        self.codeOutputHandler = codeOutputHandler
        subLayer = AVCaptureVideoPreviewLayer()
            super.init()
        if let captureSession = self.createCaptureSession() {
            self.captureSession = captureSession
            let previewLayer = self.createPreviewLayer(withCaptureSession: captureSession, view: view)
           subLayer = previewLayer
            view.layer.addSublayer(previewLayer)
        }
    }
    
    func scannerDelegate(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        self.requestCaptureSessionStopRunning()
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
                return
            }
            
            guard let stringValue = readableObject.stringValue else {
                return
            }
        self.codeOutputHandler(stringValue)
        }
        //This is where we will get the value from the barcode/qrcode
    }
    
    func requestCaptureSessionStartRunning() {
        guard let captureSession = self.captureSession else {
            return
        }
        
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    func requestCaptureSessionStopRunning() {
        guard let captureSession = self.captureSession else {
            return
        }
        
        if captureSession.isRunning {
            captureSession.stopRunning()
            print("removing sublayerS")
            subLayer.removeFromSuperlayer()
        }
    }
    
    private func metaObjectTypes() -> [AVMetadataObject.ObjectType]
    {
        return [.qr, .code128, .code39, .code39Mod43, .code93, .ean13, .ean8, .interleaved2of5, .itf14, .pdf417, .upce, .aztec, .dataMatrix, .face]
    }
    
    private func createPreviewLayer(withCaptureSession captureSession: AVCaptureSession, view: UIView) -> AVCaptureVideoPreviewLayer
    {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        return previewLayer
    }
    
    private func createCaptureSession() -> AVCaptureSession? {
        let captureSession = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return nil
        }
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            let metaDataOutput = AVCaptureMetadataOutput()
            
            //add device input
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            } else {
                return nil
            }
            
            //add metadata output
            if captureSession.canAddOutput(metaDataOutput) {
                captureSession.addOutput(metaDataOutput)
                
                if let viewController = self.viewController as? AVCaptureMetadataOutputObjectsDelegate {
                    metaDataOutput.setMetadataObjectsDelegate(viewController, queue: DispatchQueue.main)
                    metaDataOutput.metadataObjectTypes = self.metaObjectTypes()
                }
            } else {
                return nil
            }
        } catch {
            return nil
            }
        return captureSession
    }
}
