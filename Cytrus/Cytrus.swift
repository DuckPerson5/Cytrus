//
//  Cytrus.swift
//  Cytrus
//
//  Created by Jarrod Norwell on 29/2/2024.
//

import Foundation
import QuartzCore.CAMetalLayer

public struct Cytrus {
    public static let shared = Cytrus()
    
    fileprivate let cytrusObjC = CytrusObjC.shared()
    
    public func configure(layer: CAMetalLayer, with size: CGSize) {
        cytrusObjC.configure(layer: layer, with: size)
    }
    
    public func information(for url: URL) -> Information {
        cytrusObjC.gameInformation.information(for: url)
    }
    
    public func insert(game url: URL) {
        cytrusObjC.insert(game: url)
    }
    
    public func step() {
        cytrusObjC.step()
    }
    
    public func orientationChanged(orientation: UIInterfaceOrientation, for surface: CAMetalLayer) {
        cytrusObjC.orientationChanged(orientation: orientation, for: surface)
    }
    
    public func touchBegan(at point: CGPoint) {
        cytrusObjC.touchBegan(at: point)
    }
    
    public func touchEnded() {
        cytrusObjC.touchEnded()
    }
    
    public func touchMoved(at point: CGPoint) {
        cytrusObjC.touchMoved(at: point)
    }
    
    public func thumbstickMoved(_ button: VirtualControllerButtonType, x: Float, y: Float) {
        cytrusObjC.thumbstickMoved(button, x: CGFloat(x), y: CGFloat(y))
    }
    
    public func virtualControllerButtonDown(_ button: VirtualControllerButtonType) {
        cytrusObjC.virtualControllerButtonDown(button)
    }
    
    public func virtualControllerButtonUp(_ button: VirtualControllerButtonType) {
        cytrusObjC.virtualControllerButtonUp(button)
    }
}
