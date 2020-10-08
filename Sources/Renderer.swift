//
//  Renderer.swift
//  RoughSwift-iOS
//
//  Created by khoa on 20/03/2019.
//  Copyright © 2019 Khoa Pham. All rights reserved.
//

import Foundation

/// Convert Drawable to UIBezierPath and add to CAShapeLayer
public class Renderer {
  /// The layer that many shape layers will be rendered onto
  public let layer: CALayer
  
  public init(layer: CALayer) {
    self.layer = layer
  }
  
  public func handle(drawable: Drawable) {
    let pairs = drawable.sets.map({
      return ($0, self.shapeLayer(set: $0, options: drawable.options))
    })
    
    pairs.forEach { pair in
      let shapeLayer = pair.1
      layer.addSublayer(shapeLayer)
      shapeLayer.frame = layer.bounds
    }
    
    handlePath2DIfAny(pairs: pairs, options: drawable.options)
  }
  
  private func shapeLayer(set: OperationSet, options: Options) -> CAShapeLayer {
    let layer = CAShapeLayer()
    let path = CGMutablePath()
    layer.fillColor = nil
    
    switch set.type {
    case .path:
      layer.strokeColor = options.stroke.cgColor
      layer.lineWidth = CGFloat(options.strokeWidth)
    case .fillSketch:
      fillSketch(path: path, layer: layer, options: options)
    case .fillPath:
      fillPath(layer: layer, options: options)
    case .path2DFill:
      fillPath(layer: layer, options: options)
    case .path2DPattern:
      fillSketch(path: path, layer: layer, options: options)
      break
    }
    
    set.operations.forEach { op in
      operate(op: op, path: path)
    }
    
    layer.path = path
    return layer
  }
  
  /// Sketch style fill, using many stroke paths
  private func fillSketch(path: CGMutablePath, layer: CAShapeLayer, options: Options) {
    var fweight = options.fillWeight
    if (fweight < 0) {
      fweight = options.strokeWidth / 2
    }
    
    layer.lineWidth = CGFloat(fweight)
    layer.strokeColor = options.fill.cgColor
  }
  
  /// Solid fill, using fill layer
  private func fillPath(layer: CAShapeLayer, options: Options) {
    layer.fillColor = options.fill.cgColor
  }
  
  private func operate(op: Operation, path: CGMutablePath) {
    switch op {
    case let op as Move:
      path.move(to: op.point.toCGPoint())
    case let op as LineTo:
      path.addLine(to: op.point.toCGPoint())
    case let op as BezierCurveTo:
      path.addCurve(
        to: op.point.toCGPoint(),
        control1: op.controlPoint1.toCGPoint(),
        control2: op.controlPoint2.toCGPoint(),
        transform: .identity
      )
    case let op as QuadraticCurveTo:
      path.addQuadCurve(
        to: op.point.toCGPoint(),
        control: op.controlPoint.toCGPoint(),
        transform: .identity
      )
    default:
      break
    }
  }
  
  /// Apply mask for path2DFill or path2DPattern
  private func handlePath2DIfAny(pairs: [(OperationSet, CAShapeLayer)], options: Options) {
    guard let pair = pairs.first(where: { $0.0.path != nil }) else {
      return
    }
    
    let set = pair.0
    let fillLayer = pair.1
    
    // Apply mask
    let maskLayer = CAShapeLayer()
    maskLayer.path = CGPath.from(svgPath: pair.0.path!)
    scalePathToFrame(shapeLayer: maskLayer)
    fillLayer.mask = maskLayer
  
    // Somehow fillLayer loses backgroundColor, set fillColor again
    if (set.type == .path2DFill) {
      fillLayer.backgroundColor = options.fill.cgColor
    }
    
    pairs.forEach {
      scalePathToFrame(shapeLayer: $0.1)
    }
  }
  
  /// For svg path, make all path within frame
  private func scalePathToFrame(shapeLayer: CAShapeLayer) {
    guard let path = shapeLayer.path else {
      return
    }

    let rect = CGRect(
        x: 0,
        y: 0,
        width: max(layer.frame.self.width, 1),
        height: max(layer.frame.size.height, 1)
    )

    shapeLayer.path = path.fit(into: rect).moveCenter(to: rect.center)
  }
}

extension Point {
  func toCGPoint() -> CGPoint {
    return CGPoint(x: CGFloat(x), y: CGFloat(y))
  }
}

// https://github.com/onmyway133/blog/issues/232

extension CGRect {
    var center: CGPoint {
        return CGPoint( x: self.size.width/2.0,y: self.size.height/2.0)
    }
}

extension CGPoint {
    func vector(to p1:CGPoint) -> CGVector {
        return CGVector(dx: p1.x - x, dy: p1.y - y)
    }
}

extension CGPath {
    func moveCenter(to:CGPoint) -> CGPath {
        let bounds = boundingBox
        let center = bounds.center

        let zeroedTo = CGPoint(x: to.x - bounds.origin.x, y: to.y - bounds.origin.y)
        let vector = center.vector(to: zeroedTo)

        return offset(to: CGSize(width: vector.dx, height: vector.dy))
    }

    func offset(to offset:CGSize) -> CGPath {
        let t = CGAffineTransform(translationX: offset.width, y: offset.height)
        return applyCentered(transform: t)
    }

    func fit(into:CGRect) -> CGPath {
        let bounds = boundingBox

        let sw     = into.size.width/bounds.width
        let sh     = into.size.height/bounds.height
        let factor = min(sw, max(sh, 0.0))

        return scale(x: factor, y: factor)
    }

    func scale(x:CGFloat, y:CGFloat) -> CGPath {
        let scale = CGAffineTransform(scaleX: x, y: y)
        return applyCentered(transform: scale)
    }

    func applyCentered(transform: @autoclosure () -> CGAffineTransform ) -> CGPath {
        let bound  = boundingBox
        let center = CGPoint(x: bound.midX, y: bound.midY)
        var xform  = CGAffineTransform.identity

        xform = xform.concatenating(CGAffineTransform(translationX: -center.x, y: -center.y))
        xform = xform.concatenating(transform())
        xform = xform.concatenating(CGAffineTransform(translationX: center.x, y: center.y))
      
        guard let path = copy(using: &xform) else {
            fatalError("Couldn't transform path")
        }

        return path
    }
}
