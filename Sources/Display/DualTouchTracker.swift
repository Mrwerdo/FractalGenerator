//
//  DualTouchTracker.swift
//  Display
//
//  Created by Andrew Thompson on 3/9/17.
//

import Cocoa

protocol TrackerDelegate: class {
    func beginTracking(sender: DualTouchTracker)
    func updateTracking(sender: DualTouchTracker)
    func endTracking(sender: DualTouchTracker)
    
}

class DualTouchTracker {
    
    weak var delegate: TrackerDelegate?
    weak var view: NSView?
    var isTracking: Bool = false
    var initialTouches: (NSTouch, NSTouch)?
    var currentTouches: (NSTouch, NSTouch)?
    var initialPoint: NSPoint?
    var threshold: CGFloat = 1
    var modifiers: NSEvent.ModifierFlags?
    
    func touchesBegan(with event: NSEvent) {
        let touches = Array(event.touches(matching: .touching, in: view))
        
        switch touches.count {
        case 2:
            initialPoint = view?.convert(event.locationInWindow, from: nil)
            initialTouches = (touches[0], touches[1])
            currentTouches = initialTouches
        default:
            if isTracking {
                cancelTracking()
            } else {
                releaseTouches()
            }
        }
    }
    
    func touchesMoved(with event: NSEvent) {
        modifiers = event.modifierFlags
        let touches = Array(event.touches(matching: .touching, in: view))
        
        guard
            let initialTouches = self.initialTouches,
            touches.count == 2
        else {
            return
        }
        
        if (initialTouches.0.identity.isEqual(touches[0].identity) && initialTouches.1.identity.isEqual(touches[1].identity)) {
            currentTouches = (touches[0], touches[1])
        } else if (initialTouches.0.identity.isEqual(touches[1].identity) && initialTouches.1.identity.isEqual(touches[0].identity)) {
            currentTouches = (touches[1], touches[0])
        } else {
            cancelTracking()
        }
        
        if !isTracking {
            
            let deltaOrigin = self.computeDeltaOrigin()
            let deltaSize = self.computeDeltaSize()
            
            if (fabs(deltaOrigin.x) > threshold || fabs(deltaOrigin.y) > threshold || fabs(deltaSize.width) > threshold || fabs(deltaSize.height) > threshold) {
                isTracking = true
                delegate?.beginTracking(sender: self)
            }
        } else {
            delegate?.updateTracking(sender: self)
        }
    }
    
    func touchesEnded(with event: NSEvent) {
        modifiers = event.modifierFlags
        cancelTracking()
    }
    
    func touchesCancelled(with event: NSEvent) {
        cancelTracking()
    }
    
    func cancelTracking() {
        if isTracking {
            delegate?.endTracking(sender: self)
            isTracking = false
            releaseTouches()
        }
    }
    
    func releaseTouches() {
        initialTouches = nil
        currentTouches = nil
    }
    
    func computeDeltaOrigin() -> CGPoint {
        guard let initialTouches = self.initialTouches,
            let currentTouches = self.currentTouches else {
                return .zero
        }
        
        let x1 = min(initialTouches.0.normalizedPosition.x, initialTouches.1.normalizedPosition.x)
        let x2 = min(currentTouches.0.normalizedPosition.x, currentTouches.1.normalizedPosition.x)
        let y1 = min(initialTouches.0.normalizedPosition.y, initialTouches.1.normalizedPosition.y)
        let y2 = min(currentTouches.0.normalizedPosition.y, currentTouches.1.normalizedPosition.y)
        
        let deviceSize = initialTouches.0.deviceSize
        return CGPoint(x: (x2 - x1) * deviceSize.width,
                       y: (y2 - y1) * deviceSize.height)
    }
    
    func computeDeltaSize() -> CGSize {
        guard let initialTouches = self.initialTouches,
            let currentTouches = self.currentTouches else {
                return .zero
        }
        
        var x1 = min(initialTouches.0.normalizedPosition.x, initialTouches.1.normalizedPosition.x);
        var x2 = max(initialTouches.0.normalizedPosition.x, initialTouches.1.normalizedPosition.x);
        let width1 = x2 - x1;
        
        var y1 = min(initialTouches.0.normalizedPosition.y, initialTouches.1.normalizedPosition.y);
        var y2 = max(initialTouches.0.normalizedPosition.y, initialTouches.1.normalizedPosition.y);
        let height1 = y2 - y1;
        
        x1 = min(currentTouches.0.normalizedPosition.x, currentTouches.1.normalizedPosition.x);
        x2 = max(currentTouches.0.normalizedPosition.x, currentTouches.1.normalizedPosition.x);
        let width2 = x2 - x1;
        
        y1 = min(currentTouches.0.normalizedPosition.y, currentTouches.1.normalizedPosition.y);
        y2 = max(currentTouches.0.normalizedPosition.y, currentTouches.1.normalizedPosition.y);
        let height2 = y2 - y1;
        
        let deviceSize = initialTouches.0.deviceSize
        return CGSize(width: (width2 - width1) * deviceSize.width,
                      height: (height2 - height1) * deviceSize.height)
        
    }
}
