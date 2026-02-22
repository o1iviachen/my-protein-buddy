/**
 BarcodeScannerViewController.swift
 my-protein-buddy
 This file runs the barcode scanning component
 History:
 Feb 21, 2026: File creation
*/

import UIKit
import AVFoundation


protocol BarcodeScannerDelegate: AnyObject {
    /**
     A protocol that communicates the scanned barcode back to the presenting View Controller.
     */

    func didScanBarcode(barcode: String)
}


class BarcodeScannerViewController: UIViewController {
    /**
     A class that uses the device camera to scan and detect food barcodes. It uses AVFoundation to capture
     EAN-13 barcodes and passes the result back via its delegate.

     - Properties:
        - delegate (Optional BarcodeScannerDelegate): The delegate to receive scanned barcode values.
        - captureSession (AVCaptureSession): Manages the camera input and metadata output.
        - previewLayer (AVCaptureVideoPreviewLayer): Displays the live camera feed.
        - hasDetectedBarcode (Bool): Prevents multiple detections for the same scan.
     */

    weak var delegate: BarcodeScannerDelegate?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var hasDetectedBarcode = false


    override func viewDidLoad() {
        /**
         Called after the View Controller is loaded. Sets up the camera capture session for barcode scanning.
         */

        super.viewDidLoad()

        view.backgroundColor = .black

        // Initialise capture session
        captureSession = AVCaptureSession()

        // Get the default video capture device (rear camera)
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showCameraUnavailableAlert()
            return
        }

        // Create video input from the capture device
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            showCameraUnavailableAlert()
            return
        }

        // Add input to capture session
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            showCameraUnavailableAlert()
            return
        }

        // Create metadata output to detect barcodes
        let metadataOutput = AVCaptureMetadataOutput()

        // Add output to capture session
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
        } else {
            showCameraUnavailableAlert()
            return
        }

        // Set self as the metadata output's delegate and specify barcode types to detect
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.ean13, .ean8, .upce]

        // Create preview layer to display camera feed
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Add close button
        setupCloseButton()

        // Add scan guide overlay
        setupScanGuide()

        // Start capture session on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }


    override func viewWillAppear(_ animated: Bool) {
        /**
         Resumes the capture session when the View Controller appears.
         */

        super.viewWillAppear(animated)

        // Reset detection flag
        hasDetectedBarcode = false

        // Resume capture session if it was stopped
        if captureSession != nil && !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }


    override func viewWillDisappear(_ animated: Bool) {
        /**
         Stops the capture session when the View Controller disappears.
         */

        super.viewWillDisappear(animated)

        if captureSession != nil && captureSession.isRunning {
            captureSession.stopRunning()
        }
    }


    func setupCloseButton() {
        /**
         Creates and positions a close button in the top-left corner to dismiss the scanner.
         */

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 20
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }


    func setupScanGuide() {
        /**
         Creates a rectangular guide overlay in the center of the screen to help the user aim the barcode.
         */

        let guideWidth: CGFloat = 280
        let guideHeight: CGFloat = 140
        let guideX = (view.bounds.width - guideWidth) / 2
        let guideY = (view.bounds.height - guideHeight) / 2

        let guideView = UIView(frame: CGRect(x: guideX, y: guideY, width: guideWidth, height: guideHeight))
        guideView.layer.borderColor = UIColor.white.cgColor
        guideView.layer.borderWidth = 2
        guideView.layer.cornerRadius = 12
        guideView.backgroundColor = .clear
        view.addSubview(guideView)

        // Add instruction label below the guide
        let instructionLabel = UILabel()
        instructionLabel.text = "align barcode within frame"
        instructionLabel.textColor = .white
        instructionLabel.font = UIFont.systemFont(ofSize: 14)
        instructionLabel.textAlignment = .center
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)

        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: guideView.bottomAnchor, constant: 16),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }


    @objc func closeTapped() {
        /**
         Dismisses the barcode scanner.
         */

        dismiss(animated: true)
    }


    func showCameraUnavailableAlert() {
        /**
         Displays an alert when the camera is not available and dismisses the scanner.
         */

        let alertManager = AlertManager()
        alertManager.showAlert(alertMessage: "camera is not available on this device.", viewController: self) {
            self.dismiss(animated: true)
        }
    }
}


//MARK: - AVCaptureMetadataOutputObjectsDelegate
extension BarcodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    /**
     An extension that processes detected barcode metadata from the camera feed.
     */


    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        /**
         Called when a barcode is detected in the camera feed. Extracts the barcode value and passes it to the delegate.

         - Parameters:
            - output (AVCaptureMetadataOutput): The metadata output that detected the barcode.
            - metadataObjects (Array): The array of detected metadata objects.
            - connection (AVCaptureConnection): The connection from which the metadata was received.
         */

        // Prevent multiple detections
        guard !hasDetectedBarcode else { return }

        // Get the first readable barcode
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let barcodeValue = readableObject.stringValue else { return }

        // Mark as detected to prevent duplicates
        hasDetectedBarcode = true

        // Provide haptic feedback
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        // Stop capture session
        captureSession.stopRunning()

        // Pass barcode to delegate and dismiss
        delegate?.didScanBarcode(barcode: barcodeValue)
        dismiss(animated: true)
    }
}
