//
//  BarcodeScannerViewController.swift
//  my-protein-buddy
//
//  Created by olivia chen on 2025-08-25.
//

import AVFoundation
import UIKit

class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    let proteinCallManager = ProteinCallManager()
    let alertManager = AlertManager()
    var scannedFood: Food? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput = try! AVCaptureDeviceInput(device: videoCaptureDevice)
        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(metadataOutput)

        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.ean13, .ean8, .upce, .code128] // common food UPCs

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let barcode = obj.stringValue {
            let scanRequest = proteinCallManager.prepareRequest(requestString: barcode, urlString: "https://trackapi.nutritionix.com/v2/search/item", httpMethod: "GET")
            proteinCallManager.performProteinRequest(request: scanRequest) { food in
                if let safeFood = food {
                    self.scannedFood = safeFood
                    self.performSegue(withIdentifier: K.cameraResultSegue, sender: self)
                } else {
                    self.alertManager.showAlert(alertMessage: "no foods were found.", viewController: self)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /**
         Prepares and passes the selected foor item data before transitioning to the Results View Controller.
         
         - Parameters:
            - segue (UIStoryboardSegue): Indicates the View Controllers involved in the segue.
            - sender (Optional Any): Indicates the object that initiated the segue.
         */
        
        // If segue being prepared goes to results view controller, pass selected food for results view controller's attributes
        if segue.identifier == K.cameraResultSegue {
            let destinationVC = segue.destination as! ResultViewController
            destinationVC.selectedFood = scannedFood
        }
    }
}
