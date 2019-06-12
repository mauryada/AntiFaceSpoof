//
//  ConfidenceGauge.swift
//  SmartCameraTFInceptionV1
//
//  Created by Maurya, Daewoo on 6/6/19.
//  Copyright © 2019 Maurya, Daewoo. All rights reserved.
//

import UIKit

final class ConfidenceGauge: UIView {
   
   var confidence = CGFloat(1) {
      didSet { updateGaugeBounds() }
   }
   
   override init(frame: CGRect) {
      super.init(frame: frame)
      finishInit()
   }
   
   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      finishInit()
   }
   
   override func layoutSubviews() {
      super.layoutSubviews()
      gaugeLayer.position = CGPoint(x: bounds.minX, y: bounds.midY)
      gaugeLayer.targetWidth = bounds.width
      updateGaugeBounds()
   }
   
   // MARK: Private
   private let gaugeLayer = ConfidenceGaugeLayer()
   
}


// MARK: - Private
private extension ConfidenceGauge {
   
   func finishInit() {
      backgroundColor = nil
      
      gaugeLayer.anchorPoint = CGPoint(x: 0.0, y: 0.5)
      layer.addSublayer(gaugeLayer)
      setNeedsLayout()
   }
   
   func updateGaugeBounds() {
      let newSize = CGSize(width: confidence * bounds.width, height: bounds.height)
      gaugeLayer.bounds = CGRect(origin: .zero, size: newSize)
   }
   
}
