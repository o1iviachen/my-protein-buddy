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
    var isProcessingBarcode = false

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoadingIndicator()
        checkCameraPermission()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession != nil && !captureSession.isRunning {
            isProcessingBarcode = false
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession != nil && captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setupCaptureSession()
                    } else {
                        self.showPermissionDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDeniedAlert()
        @unknown default:
            showPermissionDeniedAlert()
        }
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please enable camera access in Settings to scan barcodes.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
            self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func setupCaptureSession() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            alertManager.showAlert(alertMessage: "Unable to access camera.", viewController: self)
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)

            guard captureSession.canAddInput(videoInput) else {
                alertManager.showAlert(alertMessage: "Unable to configure camera input.", viewController: self)
                return
            }
            captureSession.addInput(videoInput)

            let metadataOutput = AVCaptureMetadataOutput()

            guard captureSession.canAddOutput(metadataOutput) else {
                alertManager.showAlert(alertMessage: "Unable to configure camera output.", viewController: self)
                return
            }
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8, .upce, .code128]

            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            view.bringSubviewToFront(loadingIndicator)

            captureSession.startRunning()
        } catch {
            alertManager.showAlert(alertMessage: "Failed to setup camera: \(error.localizedDescription)", viewController: self)
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !isProcessingBarcode else { return }

        if let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let barcode = obj.stringValue {
            isProcessingBarcode = true
            captureSession.stopRunning()
            loadingIndicator.startAnimating()

            let scanRequest = proteinCallManager.prepareRequest(requestString: barcode, urlString: "https://trackapi.nutritionix.com/v2/search/item", httpMethod: "GET")
            proteinCallManager.performProteinRequest(request: scanRequest) { food in
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()

                    if let safeFood = food {
                        self.scannedFood = safeFood
                        self.performSegue(withIdentifier: K.cameraResultSegue, sender: self)
                    } else {
                        self.alertManager.showAlert(alertMessage: "No foods were found.", viewController: self) {
                            self.isProcessingBarcode = false
                            self.captureSession.startRunning()
                        }
                    }
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
