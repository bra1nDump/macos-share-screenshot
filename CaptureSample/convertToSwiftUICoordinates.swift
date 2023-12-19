//
//  ConvertFromFlippedMacOSCooridnateSystem.swift
//  CaptureSample
//
//  Created by Kirill Dubovitskiy on 12/19/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import AppKit

func convertToSwiftUICoordinates(_ point: CGPoint, in window: NSWindow) -> CGPoint {
    // Get the height of the window
    let windowHeight = window.frame.height

    // Flip the Y-coordinate
    let newY = windowHeight - point.y

    // Return the adjusted point
    return CGPoint(x: point.x, y: newY)
}
