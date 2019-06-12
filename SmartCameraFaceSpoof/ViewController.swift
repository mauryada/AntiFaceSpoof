//
//  ViewController.swift
//  SmartCameraTFInceptionV1
//
//  Created by Maurya, Daewoo on 6/3/19.
//  Copyright © 2019 Maurya, Daewoo. All rights reserved.
//

import UIKit
import AVKit
import Vision
import Accelerate

class ViewController: UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate {

   @IBOutlet var displayMessage: UILabel!
   @IBOutlet var MNISTLabel: UILabel!
   @IBOutlet var switchCam: UIButton!
   
   @IBOutlet weak var previewView: UIView!
   
   @IBOutlet weak var displayMessageFaceSpoof: UILabel!
   
   // AVCapture variables to hold sequence data
   var session: AVCaptureSession?
   var previewLayer: AVCaptureVideoPreviewLayer?
   
   var videoDataOutput: AVCaptureVideoDataOutput?
   var videoDataOutputQueue: DispatchQueue?
   
   var captureDevice: AVCaptureDevice?
   var captureDeviceResolution: CGSize = CGSize()
   
   // Layer UI for drawing Vision results
   var rootLayer: CALayer?
   var detectionOverlayLayer: CALayer?
   var detectedFaceRectangleShapeLayer: CAShapeLayer?
   var detectedFaceLandmarksShapeLayer: CAShapeLayer?
   var modelOutputTextLayer: CATextLayer?
   
   // Vision requests
   private var detectionRequests: [VNDetectFaceRectanglesRequest]?
   private var trackingRequests: [VNTrackObjectRequest]?
   
   lazy var sequenceRequestHandler = VNSequenceRequestHandler()
   
   var rectFace = CGRect(x: 0, y: 0, width: 0, height: 0)
   
//   var cameraView: CustomView? {
//      return view as? CustomView
//   }
   
   var classificationMessage = "This is a message"
   var MNISTLabelMessage = "Label for saved Model"
   
//   var detectionRequests: [VNDetectFaceRectanglesRequest]?
//   var trackingRequests: [VNTrackingRequest]?
   
   var rectLayer = CALayer()
   
   var image: UIImage!
   
   @IBAction func buttonPressed(sender: Any) {
      print("get called")
   }
   
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      self.session = self.setupAVCaptureSession()
      self.prepareVisionRequest()
      self.session?.startRunning()
      
      
      
      // Do any additional setup after loading the view.
      
//      self.displayMessage.text = self.classificationMessage
//
//      //Here is where we start up the camera
//      let captureSession = AVCaptureSession()
//      captureSession.sessionPreset = .high
//
//      let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
//
//      if let device = deviceDiscoverySession.devices.first {
//         if let deviceInput = try? AVCaptureDeviceInput(device: device) {
//            if captureSession.canAddInput(deviceInput) {
//               captureSession.addInput(deviceInput)
//            }
//         }
//      }
//
//      captureSession.startRunning()
//
//      let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//
////      view.layer.addSublayer(previewLayer)
//      view.layer.insertSublayer(previewLayer, at: 0)
//      previewLayer.videoGravity = .resizeAspectFill
//
////      customViewRef.frame = view.frame
//
//      previewLayer.frame = view.frame
//
//      let dataOutput = AVCaptureVideoDataOutput()
//      dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
//      captureSession.addOutput(dataOutput)
      
   }
   /// - Tag: CreateCaptureSession
   fileprivate func setupAVCaptureSession() -> AVCaptureSession? {
      let captureSession = AVCaptureSession()
      do {
         let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
         if let device = deviceDiscoverySession.devices.first {
            if let inputDevice = try? AVCaptureDeviceInput(device: device) {
               let candidateDimensions = CMVideoFormatDescriptionGetDimensions(inputDevice.device.activeFormat.formatDescription)
               let resolution1 = CGSize(width: CGFloat(candidateDimensions.width), height: CGFloat(candidateDimensions.height))
               if captureSession.canAddInput(inputDevice) {
                  captureSession.addInput(inputDevice)
                  
                  self.configureVideoDataOutput(for: device, resolution: resolution1, captureSession: captureSession)
               }
            }
         }
//         let inputDevice = try self.configureFrontCamera(for: captureSession)
//         self.configureVideoDataOutput(for: inputDevice, resolution: resolution, captureSession: captureSession)
         self.designatePreviewLayer(for: captureSession)
         return captureSession
      } catch let executionError as NSError {
         self.presentError(executionError)
      } catch {
         self.presentErrorAlert(message: "An unexpected failure has occured")
      }
      
      self.teardownAVCapture()
      
      return nil
   }
   
   // MARK: Helper Methods for Error Presentation
   
   fileprivate func presentErrorAlert(withTitle title: String = "Unexpected Failure", message: String) {
      let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
      self.present(alertController, animated: true)
   }
   
   fileprivate func presentError(_ error: NSError) {
      self.presentErrorAlert(withTitle: "Failed with error \(error.code)", message: error.localizedDescription)
   }
   
   // Removes infrastructure for AVCapture as part of cleanup.
   fileprivate func teardownAVCapture() {
      self.videoDataOutput = nil
      self.videoDataOutputQueue = nil
      
      if let previewLayer = self.previewLayer {
         previewLayer.removeFromSuperlayer()
         self.previewLayer = nil
      }
   }

   
   /// - Tag: CreateSerialDispatchQueue
   fileprivate func configureVideoDataOutput(for inputDevice: AVCaptureDevice, resolution: CGSize, captureSession: AVCaptureSession) {
      
      let videoDataOutput = AVCaptureVideoDataOutput()
      videoDataOutput.alwaysDiscardsLateVideoFrames = true
      
      // Create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured.
      // A serial dispatch queue must be used to guarantee that video frames will be delivered in order.
      let videoDataOutputQueue = DispatchQueue(label: "com.example.apple-samplecode.VisionFaceTrack")
      videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
      
      if captureSession.canAddOutput(videoDataOutput) {
         captureSession.addOutput(videoDataOutput)
      }
      
//      videoDataOutput.connection(with: .video)?.isEnabled = true
//
//      if let captureConnection = videoDataOutput.connection(with: AVMediaType.video) {
//         if captureConnection.isCameraIntrinsicMatrixDeliverySupported {
//            captureConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
//         }
//      }
      
      self.videoDataOutput = videoDataOutput
      self.videoDataOutputQueue = videoDataOutputQueue
      
      self.captureDevice = inputDevice
      self.captureDeviceResolution = resolution
   }
   
   /// - Tag: ConfigureDeviceResolution
   fileprivate func highestResolution420Format(for device: AVCaptureDevice) -> (format: AVCaptureDevice.Format, resolution: CGSize)? {
      var highestResolutionFormat: AVCaptureDevice.Format? = nil
      var highestResolutionDimensions = CMVideoDimensions(width: 0, height: 0)
      
      for format in device.formats {
         let deviceFormat = format as AVCaptureDevice.Format
         
         let deviceFormatDescription = deviceFormat.formatDescription
         if CMFormatDescriptionGetMediaSubType(deviceFormatDescription) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
            let candidateDimensions = CMVideoFormatDescriptionGetDimensions(deviceFormatDescription)
            if (highestResolutionFormat == nil) || (candidateDimensions.width > highestResolutionDimensions.width) {
               highestResolutionFormat = deviceFormat
               highestResolutionDimensions = candidateDimensions
            }
         }
      }
      
      if highestResolutionFormat != nil {
         let resolution = CGSize(width: CGFloat(highestResolutionDimensions.width), height: CGFloat(highestResolutionDimensions.height))
         return (highestResolutionFormat!, resolution)
      }
      
      return nil
   }
   
   fileprivate func configureFrontCamera(for captureSession: AVCaptureSession) throws -> (device: AVCaptureDevice, resolution: CGSize) {
      let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
      
      if let device = deviceDiscoverySession.devices.first {
         if let deviceInput = try? AVCaptureDeviceInput(device: device) {
            if captureSession.canAddInput(deviceInput) {
               captureSession.addInput(deviceInput)
            }
            
            if let highestResolution = self.highestResolution420Format(for: device) {
               try device.lockForConfiguration()
               device.activeFormat = highestResolution.format
               device.unlockForConfiguration()
               
               return (device, highestResolution.resolution)
            }
         }
      }
      
      throw NSError(domain: "ViewController", code: 1, userInfo: nil)
   }
   
   /// - Tag: DesignatePreviewLayer
   fileprivate func designatePreviewLayer(for captureSession: AVCaptureSession) {
      let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
      self.previewLayer = videoPreviewLayer
      
      videoPreviewLayer.name = "CameraPreview"
      videoPreviewLayer.backgroundColor = UIColor.black.cgColor
      videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
      
      if let previewRootLayer = self.previewView?.layer {
         self.rootLayer = previewRootLayer
         
         previewRootLayer.masksToBounds = true
         videoPreviewLayer.frame = previewRootLayer.bounds
         previewRootLayer.addSublayer(videoPreviewLayer)
      }
   }
   
   //#########################################################################################
   
   // MARK: Performing Vision Requests
   
   /// - Tag: WriteCompletionHandler
   fileprivate func prepareVisionRequest() {
      
      //self.trackingRequests = []
      var requests = [VNTrackObjectRequest]()
      
      let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request, error) in
         
         if error != nil {
            print("FaceDetection error: \(String(describing: error)).")
         }
         
         guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
            let results = faceDetectionRequest.results as? [VNFaceObservation] else {
               return
         }
         DispatchQueue.main.async {
            // Add the observations to the tracking list
            for observation in results {
               let faceTrackingRequest = VNTrackObjectRequest(detectedObjectObservation: observation)
               requests.append(faceTrackingRequest)
            }
            self.trackingRequests = requests
         }
      })
      
      // Start with detection.  Find face, then track it.
      self.detectionRequests = [faceDetectionRequest]
      
      self.sequenceRequestHandler = VNSequenceRequestHandler()
      
      self.setupVisionDrawingLayers()
   }
   
   // MARK: Drawing Vision Observations
   
   fileprivate func setupVisionDrawingLayers() {
      let captureDeviceResolution = self.captureDeviceResolution
      
      let captureDeviceBounds = CGRect(x: 0,
                                       y: 0,
                                       width: captureDeviceResolution.width,
                                       height: captureDeviceResolution.height)
      
      let captureDeviceBoundsCenterPoint = CGPoint(x: captureDeviceBounds.midX,
                                                   y: captureDeviceBounds.midY)
      
      let normalizedCenterPoint = CGPoint(x: 0.5, y: 0.5)
      
      guard let rootLayer = self.rootLayer else {
         self.presentErrorAlert(message: "view was not property initialized")
         return
      }
      
      let overlayLayer = CALayer()
      overlayLayer.name = "DetectionOverlay"
      overlayLayer.masksToBounds = true
      overlayLayer.anchorPoint = normalizedCenterPoint
      overlayLayer.bounds = captureDeviceBounds
      overlayLayer.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
      
      let faceRectangleShapeLayer = CAShapeLayer()
      faceRectangleShapeLayer.name = "RectangleOutlineLayer"
      faceRectangleShapeLayer.bounds = captureDeviceBounds
      faceRectangleShapeLayer.anchorPoint = normalizedCenterPoint
      faceRectangleShapeLayer.position = captureDeviceBoundsCenterPoint
      faceRectangleShapeLayer.fillColor = nil
      faceRectangleShapeLayer.strokeColor = UIColor.green.withAlphaComponent(0.7).cgColor
      faceRectangleShapeLayer.lineWidth = 5
      faceRectangleShapeLayer.shadowOpacity = 0.7
      faceRectangleShapeLayer.shadowRadius = 5
//
//      let faceLandmarksShapeLayer = CAShapeLayer()
//      faceLandmarksShapeLayer.name = "FaceLandmarksLayer"
//      faceLandmarksShapeLayer.bounds = captureDeviceBounds
//      faceLandmarksShapeLayer.anchorPoint = normalizedCenterPoint
//      faceLandmarksShapeLayer.position = captureDeviceBoundsCenterPoint
//      faceLandmarksShapeLayer.fillColor = nil
//      faceLandmarksShapeLayer.strokeColor = UIColor.yellow.withAlphaComponent(0.7).cgColor
//      faceLandmarksShapeLayer.lineWidth = 3
//      faceLandmarksShapeLayer.shadowOpacity = 0.7
//      faceLandmarksShapeLayer.shadowRadius = 5
      
      overlayLayer.addSublayer(faceRectangleShapeLayer)
//      faceRectangleShapeLayer.addSublayer(faceLandmarksShapeLayer)
      rootLayer.addSublayer(overlayLayer)
      
      self.detectionOverlayLayer = overlayLayer
      self.detectedFaceRectangleShapeLayer = faceRectangleShapeLayer
//      self.detectedFaceLandmarksShapeLayer = faceLandmarksShapeLayer
      
      self.updateLayerGeometry()
   }
   
   fileprivate func updateLayerGeometry() {
      guard let overlayLayer = self.detectionOverlayLayer,
         let rootLayer = self.rootLayer,
         let previewLayer = self.previewLayer
         else {
            return
      }
      
      CATransaction.setValue(NSNumber(value: true), forKey: kCATransactionDisableActions)
      
      let videoPreviewRect = previewLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1))
      
      var rotation: CGFloat
      var scaleX: CGFloat
      var scaleY: CGFloat
      
      // Rotate the layer into screen orientation.
      switch UIDevice.current.orientation {
      case .portraitUpsideDown:
         rotation = 180
         scaleX = videoPreviewRect.width / captureDeviceResolution.width
         scaleY = videoPreviewRect.height / captureDeviceResolution.height

      case .landscapeLeft:
         rotation = 90
         scaleX = videoPreviewRect.height / captureDeviceResolution.width
         scaleY = scaleX

      case .landscapeRight:
         rotation = -90
         scaleX = videoPreviewRect.height / captureDeviceResolution.width
         scaleY = scaleX
         
      default:
         rotation = 0
         scaleX = videoPreviewRect.width / captureDeviceResolution.width
         scaleY = videoPreviewRect.height / captureDeviceResolution.height
      }
      
      // Scale and mirror the image to ensure upright presentation.
      let affineTransform = CGAffineTransform(rotationAngle: radiansForDegrees(rotation))
         .scaledBy(x: scaleX, y: scaleY)
      overlayLayer.setAffineTransform(affineTransform)
      
      // Cover entire screen UI.
      let rootLayerBounds = rootLayer.bounds
      overlayLayer.position = CGPoint(x: rootLayerBounds.midX, y: rootLayerBounds.midY)
   }
   
   func exifOrientationForDeviceOrientation(_ deviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
      
      switch deviceOrientation {
      case .portraitUpsideDown:
//         return .rightMirrored
         return .right
         
      case .landscapeLeft:
         return .down
         
      case .landscapeRight:
         return .up
         
      default:
         return .left
      }
   }
   
   func exifOrientationForCurrentDeviceOrientation() -> CGImagePropertyOrientation {
      return exifOrientationForDeviceOrientation(UIDevice.current.orientation)
   }
   
   fileprivate func radiansForDegrees(_ degrees: CGFloat) -> CGFloat {
      return CGFloat(Double(degrees) * Double.pi / 180.0)
   }
   
   fileprivate func addIndicators(to faceRectanglePath: CGMutablePath, faceLandmarksPath: CGMutablePath, for faceObservation: VNFaceObservation) {
      let displaySize = self.captureDeviceResolution
//      let previewLayerSize = self.previewLayer?.preferredFrameSize()
      
      let faceBounds = VNImageRectForNormalizedRect(faceObservation.boundingBox, Int(displaySize.width), Int(displaySize.height))
//      let faceBounds2 = VNImageRectForNormalizedRect(faceObservation.boundingBox, Int(previewLayerSize!.width)*3, Int(previewLayerSize!.height)*3)
//      let TempBound = CGRect(x: 500, y: 500, width: 500, height: 500)
      faceRectanglePath.addRect(faceBounds)
      self.rectFace = faceBounds
      
      
   }

   
   /// - Tag: DrawPaths
   fileprivate func drawFaceObservations(_ faceObservations: [VNFaceObservation]) {
      guard let faceRectangleShapeLayer = self.detectedFaceRectangleShapeLayer//,
        // let faceLandmarksShapeLayer = self.detectedFaceLandmarksShapeLayer
         else {
            return
      }
      
      CATransaction.begin()
      
      CATransaction.setValue(NSNumber(value: true), forKey: kCATransactionDisableActions)
      
      let faceRectanglePath = CGMutablePath()
      let faceLandmarksPath = CGMutablePath()
      
      for faceObservation in faceObservations {
         self.addIndicators(to: faceRectanglePath,
                            faceLandmarksPath: faceLandmarksPath,
                            for: faceObservation)
      }
      
      faceRectangleShapeLayer.path = faceRectanglePath
//      faceLandmarksShapeLayer.path = faceLandmarksPath
      
      self.updateLayerGeometry()
      
      CATransaction.commit()
   }
   
   //#########################################################################################
   
   func RequestDidComplete(request: VNRequest, error: Error?)
   {
      guard let results = request.results as? [VNClassificationObservation] else {return}
      
      guard let firstObservation = results.first else {return}
      
      //         print(firstObservation.identifier, firstObservation.confidence)
      
      self.classificationMessage = "\(firstObservation.identifier). \(firstObservation.confidence)"
      
   }
   
   func RequestDidComplete1(request: VNRequest, error: Error?)
   {

      guard let results = request.results as? [VNCoreMLFeatureValueObservation] else {return}

      guard let firstObservation = results.first else {return}
      
      let multiArr = firstObservation.featureValue.multiArrayValue
      
      self.classificationMessage = " Live: \(multiArr?[0].stringValue ?? "0.00" )  \n Mask:\(multiArr?[1].stringValue ?? "0.00")   \n Makeup: \(multiArr?[2].stringValue ?? "0.00")   \n Print: \(multiArr?[3].stringValue ?? "0.00")  \n Partial: \(multiArr?[4].stringValue ?? "0.00")"
      
      DispatchQueue.main.async{
         self.outputMessage()
      }
      
   }
   
   
   func handleFaceFeatures(request: VNRequest, errror: Error?) {
//      guard let observations = request.results as? [VNFaceObservation] else {
//         fatalError("unexpected result type!")
//      }
      
//      for face in observations {

         // draw the face rect
         
         
         
//         let size = CGSize(width: boundingBox.width * imageView.bounds.width,
//                           height: boundingBox.height * imageView.bounds.height)
//         let origin = CGPoint(x: boundingBox.minX * imageView.bounds.width,
//                              y: (1 - observation.boundingBox.minY) * imageView.bounds.height
//
//         let rect1 = CGRect(origin: origin, size: size)
         // UIScreen.main.bounds.width / widthPB
//      let screenWidth = UIScreen.main.bounds.width
//         let w = face.boundingBox.size.width * 375.0// * CGFloat(widthPB)
//         let h = face.boundingBox.size.height * 812.0// * CGFloat(heightPB)
//         let x = face.boundingBox.origin.x * 375.0// * CGFloat(widthPB)
//         let y = face.boundingBox.origin.y * 812.0// * CGFloat(heightPB)
//         let faceRect = CGRect(x: x, y: y, width: w, height: h)
//
////         view.draw(faceRect)
//         let renderer = UIGraphicsImageRenderer(size: faceRect.size)
//         view.draw(faceRect)
         
         
//         let cView = self.view as! CustomView
      
         
//         cView.faceRect = faceRect
         
//         let img = renderer.image { ctx in
//            ctx.cgContext.setFillColor(UIColor.red.cgColor)
//            ctx.cgContext.setStrokeColor(UIColor.green.cgColor)
//            ctx.cgContext.setLineWidth(10)
//
//
//            ctx.cgContext.addRect(faceRect)
//            ctx.cgContext.drawPath(using: .fillStroke)
//         }
//      }
   }
   
   func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

      var requestHandlerOptions: [VNImageOption: AnyObject] = [:]
      
      let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil)
      if cameraIntrinsicData != nil {
         requestHandlerOptions[VNImageOption.cameraIntrinsics] = cameraIntrinsicData
      }
      
      guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
      
      
      
      let exifOrientation = self.exifOrientationForCurrentDeviceOrientation()
      
      guard let requests = self.trackingRequests, !requests.isEmpty else {
         // No tracking object detected, so perform initial detection
         let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                         orientation: exifOrientation,
                                                         options: requestHandlerOptions)
         
         do {
            guard let detectRequests = self.detectionRequests else {
               return
            }
            try imageRequestHandler.perform(detectRequests)
         } catch let error as NSError {
            NSLog("Failed to perform FaceRectangleRequest: %@", error)
         }
         return
      }
      
      do {
         try self.sequenceRequestHandler.perform(requests,
                                                 on: pixelBuffer,
                                                 orientation: exifOrientation)
      } catch let error as NSError {
         NSLog("Failed to perform SequenceRequest: %@", error)
      }
      
      // Setup the next round of tracking.
      var newTrackingRequests = [VNTrackObjectRequest]()
      for trackingRequest in requests {
         
         guard let results = trackingRequest.results else {
            return
         }
         
         guard let observation = results[0] as? VNDetectedObjectObservation else {
            return
         }
         
         if !trackingRequest.isLastFrame {
            if observation.confidence > 0.3 {
               trackingRequest.inputObservation = observation
            } else {
               trackingRequest.isLastFrame = true
            }
            newTrackingRequests.append(trackingRequest)
         }
      }
      self.trackingRequests = newTrackingRequests
      
      if newTrackingRequests.isEmpty {
         // Nothing to track, so abort.
         return
      }
      
      // Perform face landmark tracking on detected faces.
      var faceLandmarkRequests = [VNDetectFaceLandmarksRequest]()
      
      // Perform landmark detection on tracked faces.
      for trackingRequest in newTrackingRequests {
         
         let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request, error) in
            
            if error != nil {
               print("FaceLandmarks error: \(String(describing: error)).")
            }
            
            guard let landmarksRequest = request as? VNDetectFaceLandmarksRequest,
               let results = landmarksRequest.results as? [VNFaceObservation] else {
                  return
            }
            
            // Perform all UI updates (drawing) on the main queue, not the background queue on which this handler is being called.
            DispatchQueue.main.async {
               self.drawFaceObservations(results)
            }
         })
         
         guard let trackingResults = trackingRequest.results else {
            return
         }
         
         guard let observation = trackingResults[0] as? VNDetectedObjectObservation else {
            return
         }
         let faceObservation = VNFaceObservation(boundingBox: observation.boundingBox)
         

         faceLandmarksRequest.inputFaceObservations = [faceObservation]
         
         // Continue to track detected facial landmarks.
         faceLandmarkRequests.append(faceLandmarksRequest)
         
         let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                         orientation: exifOrientation,
                                                         options: requestHandlerOptions)
         
         
         
         do {
            try imageRequestHandler.perform(faceLandmarkRequests)
         } catch let error as NSError {
            NSLog("Failed to perform FaceLandmarkRequest: %@", error)
         }
      }
      
//      let cropXfaceRect = self.rectFace.origin.x
//      let cropYfaceRect = self.rectFace.origin.y
//
//      let cropWidthFaceRect = self.rectFace.width
//      let cropHeightFaceRect = self.rectFace.height
      
//      let cropWidth = self.captureDeviceResolution.width
//      let cropHeight = self.captureDeviceResolution.height
      

//      guard let CIImg: CIImage = CIImage(cvPixelBuffer: pixelBuffer) else {return}
      
      let height = rectFace.height + rectFace.height * 0.2
      let width = rectFace.width + rectFace.width * 0.2
      let xCord = rectFace.origin.x
      let yCord = rectFace.origin.y
      
//      var rect1 = CGRect(origin: rectFace.origin, size: rectFace.size)
      var newFaceRect = CGRect(x: xCord, y: yCord, width: width, height: height)
      
      let videoPreviewRect = self.previewLayer!.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1))
      
      
      let rotation = 0
      let scaleX = videoPreviewRect.height / captureDeviceResolution.width
      let scaleY = videoPreviewRect.width / captureDeviceResolution.height
      
      let affineTransform = CGAffineTransform(rotationAngle: CGFloat(rotation))
         .scaledBy(x: scaleX, y: scaleX)
      
      var rect1 = CGRect(origin: rectFace.origin, size: rectFace.size).applying(affineTransform)
      
      newFaceRect = newFaceRect.applying(affineTransform)
      
      let CIImg = CIImage(cvPixelBuffer: pixelBuffer).oriented(.up)
      
//      let NewCIImg = CIImg.transformed(by: affineTransform)
////      CIImg = CIImg.transformed(by: affineTransform)
//
      let coppedImg = CIImg.cropped(to: newFaceRect)
      
      guard let croppedPixelBuffer = coppedImg.pixelBuffer else {return}
      
      
      guard let model = try? VNCoreMLModel(for: mobile_6_core().model) else {print("ERROR: Could not create Vision model"); return}

      let reqest = VNCoreMLRequest(model: model, completionHandler: self.RequestDidComplete1)

      try? VNImageRequestHandler(cvPixelBuffer: croppedPixelBuffer,
                                 options: [:]).perform([reqest])

      DispatchQueue.main.async{
         self.view.setNeedsDisplay()
      }
      
      
//      let UIImg = UIImage(ciImage: CIImg)
//
//
//      var CGImg = UIImg.cgImage
//
//      let context = CIContext(options: nil)
////      let contextMT = CIContext(mtlDevice: <#T##MTLDevice#>)
//      if context != nil {
//         CGImg = context.createCGImage(CIImg, from: CIImg.extent)
//      }
//      
//
//      let croppedImg = CGImg?.cropping(to: self.rectFace)
//
//      guard let cutImageRef: CGImage = UIImg.cgImage?.cropping(to:self.rectFace)
//         else {
//            return
//      }
      
//      guard let newPixelBuffer = resizePixelBuffer(pixelBuffer,
//                                             cropX: Int(cropXfaceRect),
//                                             cropY: Int(cropYfaceRect),
//                                             cropWidth: Int(cropWidthFaceRect),
//                                             cropHeight: Int(cropHeightFaceRect),
//                                             scaleWidth: Int(cropWidthFaceRect),
//                                             scaleHeight: Int(cropHeightFaceRect))
//         else {return}
      
//      CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//
//      let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
//      let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//
//
//      let startpos = Int(cropYfaceRect)*bytesPerRow+4*cropXfaceRect
//
//      let dataAdd = baseAddress + startpos
//
//      let inBuff = vImage_Buffer(data: dataAdd, height: cropHeightFaceRect, width: cropWidthFaceRect, rowBytes: bytesPerRow)
//
//      let outImg = malloc(4*outWidth*outHeight)
//

      

//      guard let model1 = try? VNCoreMLModel(for: mobile_6_core().model) else {print("ERROR: Could not create Vision model"); return}
//      let request = VNCoreMLRequest(model: model1, completionHandler: self.RequestDidComplete1)
//
//      try? VNImageRequestHandler(cvPixelBuffer: newPixelBuffer,
//                                 options: [:]).perform([request])
      
//
//      let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: self.handleFaceFeatures)
//
//      let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 1)!, options: [:])
//      do {
//         try requestHandler.perform([faceLandmarksRequest])
//      } catch {
//         print(error)
//      }
//
//      guard let model1 = try? VNCoreMLModel(for: mobile_6_core().model) else {print("ERROR: Could not create Vision model"); return}
//
//      let reqest = VNCoreMLRequest(model: model1, completionHandler: self.RequestDidComplete1)
//
//      try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
//                                 options: [:]).perform([reqest])
//
//      DispatchQueue.main.async{
//         self.view.setNeedsDisplay()
//      }
      
   }
   
   func outputMessage() {
      
      self.displayMessageFaceSpoof.text = self.classificationMessage
   }
}





public func resizePixelBuffer(_ srcPixelBuffer: CVPixelBuffer,
                              cropX: Int,
                              cropY: Int,
                              cropWidth: Int,
                              cropHeight: Int,
                              scaleWidth: Int,
                              scaleHeight: Int) -> CVPixelBuffer? {
   let flags = CVPixelBufferLockFlags(rawValue: 0)
   guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(srcPixelBuffer, flags) else {
      return nil
   }
   defer { CVPixelBufferUnlockBaseAddress(srcPixelBuffer, flags) }
   
   guard let srcData = CVPixelBufferGetBaseAddress(srcPixelBuffer) else {
      print("Error: could not get pixel buffer base address")
      return nil
   }
   let srcBytesPerRow = CVPixelBufferGetBytesPerRow(srcPixelBuffer)
   let offset = cropY*srcBytesPerRow + cropX*4
   var srcBuffer = vImage_Buffer(data: srcData.advanced(by: offset),
                                 height: vImagePixelCount(cropHeight),
                                 width: vImagePixelCount(cropWidth),
                                 rowBytes: srcBytesPerRow)
   
   let destBytesPerRow = scaleWidth*4
   guard let destData = malloc(scaleHeight*destBytesPerRow) else {
      print("Error: out of memory")
      return nil
   }
   var destBuffer = vImage_Buffer(data: destData,
                                  height: vImagePixelCount(scaleHeight),
                                  width: vImagePixelCount(scaleWidth),
                                  rowBytes: destBytesPerRow)
   
   let error = vImageScale_ARGB8888(&srcBuffer, &destBuffer, nil, vImage_Flags(0))
   if error != kvImageNoError {
      print("Error:", error)
      free(destData)
      return nil
   }
   
   let releaseCallback: CVPixelBufferReleaseBytesCallback = { _, ptr in
      if let ptr = ptr {
         free(UnsafeMutableRawPointer(mutating: ptr))
      }
   }
   
   let pixelFormat = CVPixelBufferGetPixelFormatType(srcPixelBuffer)
   var dstPixelBuffer: CVPixelBuffer?
   let status = CVPixelBufferCreateWithBytes(nil, scaleWidth, scaleHeight,
                                             pixelFormat, destData,
                                             destBytesPerRow, releaseCallback,
                                             nil, nil, &dstPixelBuffer)
   if status != kCVReturnSuccess {
      print("Error: could not create new pixel buffer")
      free(destData)
      return nil
   }
   return dstPixelBuffer
}
