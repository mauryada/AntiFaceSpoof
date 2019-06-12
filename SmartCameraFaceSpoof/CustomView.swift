//
//  customView.swift
//  SmartCameraTFInceptionV1
//
//  Created by Maurya, Daewoo on 6/6/19.
//  Copyright © 2019 Maurya, Daewoo. All rights reserved.
//
import AVFoundation
import UIKit

final class CustomView : UIView
{
//   override func viewDidLoad() {
//      super.viewDidLoad()
//
//      // Do any additional setup after loading the view.
//   }
   
   
   override init(frame: CGRect) {
      super.init(frame: frame)
      finishInit()
   }
   
   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      finishInit()
//      fatalError("init(coder:) has not been implemented")
   }
   
   var previewLayer: AVCaptureVideoPreviewLayer {
      return layer as! AVCaptureVideoPreviewLayer
   }
   
   override class var layerClass: AnyClass {
      return AVCaptureVideoPreviewLayer.self
   }
   
   var faceRect:CGRect = CGRect(x: 100.0, y: 1.0, width: 100.0, height: 100.0)
   
   override func draw(_ rect: CGRect) {
      
   
      let color:UIColor = UIColor.red
      
      let bpath:UIBezierPath = UIBezierPath(rect: faceRect)
      
      color.set()
      bpath.stroke()
      
//      print("it ran")
   }
   
   
}

private extension CustomView {
   
   func finishInit() {
      previewLayer.videoGravity = .resizeAspectFill
   }
   
}

