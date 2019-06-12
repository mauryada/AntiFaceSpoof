//
//  ConfidenceGaugeLayer.swift
//  SmartCameraTFInceptionV1
//
//  Created by Maurya, Daewoo on 6/6/19.
//  Copyright © 2019 Maurya, Daewoo. All rights reserved.
//

import QuartzCore
import UIKit.UIColor

private let _gray = UIColor.darkGray
private let _green = UIColor.green

final class ConfidenceGaugeLayer: CALayer {
   
   var targetWidth = CGFloat(0) {
      didSet { updateGradientBounds() }
   }
   
   override init() {
      super.init()
      finishInit()
   }
   
   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      finishInit()
   }
   
   override init(layer: Any) {
      super.init(layer: layer)
      finishInit()
   }
   
   override func layoutSublayers() {
      super.layoutSublayers()
      gradient.position = CGPoint(x: bounds.minX, y: bounds.midY)
      updateGradientBounds()
   }
   
   // MARK: Private
   private let gradient: CALayer = {
      let layer = CAGradientLayer()
      layer.anchorPoint = CGPoint(x: 0.0, y: 0.5)
      layer.startPoint = layer.anchorPoint
      layer.endPoint = CGPoint(x: 1.0, y: 0.5)
      layer.colors = [_gray.cgColor, _green.cgColor]
      
      return layer
   }()
   
}


// MARK - Private
private extension ConfidenceGaugeLayer {
   
   func finishInit() {
      masksToBounds = true
      insertSublayer(gradient, at: 0)
      setNeedsLayout()
   }
   
   func updateGradientBounds() {
      let newSize = CGSize(width: targetWidth, height: bounds.height)
      gradient.bounds = CGRect(origin: .zero, size: newSize)
   }
   
}
