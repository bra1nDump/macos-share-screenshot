/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An object that captures a stream of screen content.
*/

import Foundation
import ScreenCaptureKit
import OSLog

enum CaptureType {
    case independentWindow
    case display
}

struct CaptureConfiguration {
    var captureType: CaptureType = .display
    var display: SCDisplay?
    var window: SCWindow?
    var filterOutOwningApplication = true
}

struct CapturedFrame: Sendable {
    var sampleBuffer: CMSampleBuffer
    var surface: IOSurface
    var contentRect: CGRect
    var displayTime: TimeInterval
    var contentScale: Double
    var scaleFactor: Double
}

@MainActor
class ScreenRecorder: NSObject, ObservableObject, @unchecked Sendable {
    
    struct ScreenRecorderError: Error {
        let errorDescription: String
        
        init(_ description: String) {
            errorDescription = description
        }
    }
    
    @Published var latestFrame: CapturedFrame?
    @Published var error: Error?
    @Published var isRecording = false
    
    private var stream: SCStream?
    private let logger = Logger()
    private var cpuStartTime = mach_absolute_time()
    
    func startCapture(with captureConfig: CaptureConfiguration) async {
        error = nil
        isRecording = false
        
        do {
            let filter = try await contentFilter(for: captureConfig)
            
            let streamConfig = streamConfiguration(for: captureConfig)
            
            stream = SCStream(filter: filter, captureOutputProperties: streamConfig, delegate: self)
            
            try await stream?.startCapture { stream, sampleBuffer in
                Task {
                    self.handleFrame(for: stream, sampleBuffer: sampleBuffer)
                }
            }
            cpuStartTime = mach_absolute_time()
            isRecording = true
        } catch {
            logger.error("Failed to start capture: \(String(describing: error))")
            self.error = error
        }
    }
    
    func update(with captureConfig: CaptureConfiguration) async {
        do {
            let filter = try await contentFilter(for: captureConfig)
            let streamConfig = streamConfiguration(for: captureConfig)
            try await stream?.update(streamConfig)
            try await stream?.update(filter)
        } catch {
            logger.error("Failed to update the filter: \(String(describing: error))")
            self.error = error
        }
    }
    
    func stopCapture() async {
        isRecording = false
        
        do {
            try await stream?.stop()
        } catch {
            logger.error("Failed to stop capture: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    private func contentFilter(for config: CaptureConfiguration) async throws -> SCContentFilter {
        let filter: SCContentFilter
        switch config.captureType {
        case .display:
            guard let display = config.display else {
                throw ScreenRecorderError("The configuration doesn't provide a display.")
            }
            
            if config.filterOutOwningApplication {
                // Create a content filter that includes all content from a display,
                // minus the sample app's window.

                // Retrieve the screen content that's available to capture.
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                // Filter out the app matching the sample's bundle identifier.
                let excludedApps = content.applications.filter { app in
                    Bundle.main.bundleIdentifier == app.bundleIdentifier
                }
                filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: nil)
            } else {
                // Create a content filter that includes the entire display.
                filter = SCContentFilter(display: display, excludingWindows: nil)
            }
        case .independentWindow:
            guard let window = config.window else {
                throw ScreenRecorderError("The configuration doesn't provide a window.")
            }
            // Create a content filter that includes only the specified window.
            filter = SCContentFilter(desktopIndependentWindow: window)
        }
        
        return filter
    }
    
    private func streamConfiguration(for captureConfig: CaptureConfiguration) -> SCStreamConfiguration {
        let streamConfig = SCStreamConfiguration()
        
        // Set the capture size to twice the display size to support retina displays.
        if captureConfig.captureType == .display, let display = captureConfig.display {
            streamConfig.width = display.width * 2
            streamConfig.height = display.height * 2
        }
        
        // Capture at 60fps.
        streamConfig.minimumFrameTime = 1 / 60
        
        // Increase the depth of the frame queue to ensure high FPS while displaying the stream.
        // Increasing the depth also increases the memory footprint of WindowServer.
        streamConfig.queueDepth = 5
        return streamConfig
    }
    
    func handleFrame(for stream: SCStream, sampleBuffer: CMSampleBuffer) {
        guard sampleBuffer.isValid else {
            logger.log("The sample buffer is invalid.")
            return
        }
        
        // Retrieve the dictionary of metadata attachments from the sample buffer.
        // You use the attachments to retrieve data about the captured frame.
        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true) as? [[SCStreamFrameInfo: Any]],
              let attachments = attachmentsArray.first else {
            logger.error("Failed to retrieve attachments from a sample buffer.")
            return
        }
        
        guard let statusRawValue = attachments[SCStreamFrameInfo.statusKey] as? Int,
              let status = SCFrameStatus(rawValue: statusRawValue) else {
            logger.error("Failed to get the frame status from attachments.")
            return
        }
                
        guard status == .frameComplete else {
            logger.log("Not updating frame because frame status is \(String(describing: status))")
            return
        }
        
        // Retrieve the CVImageBuffer from the sample buffer.
        guard let pixelBuffer = sampleBuffer.imageBuffer else {
            logger.error("Could not get a pixel buffer from the sample buffer.")
            return
        }

        // Retrieve the IOSurfaceRef from the pixel buffer.
        guard let surfaceRef = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else {
            logger.error("Could not get an IOSurface from the pixel buffer.")
            return
        }
        
        guard let contentRectDict = attachments[.contentRectKey],
              let contentRect = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary) else {
            logger.error("Failed to get a content rectangle from the sample buffer.")
            return
        }
        
        guard let displayTime = attachments[.displayTimeKey] as? UInt64 else {
            logger.error("Failed to get a display time from the sample buffer.")
            return
        }
        
        let elapsedTime = convertToSeconds(displayTime) - convertToSeconds(cpuStartTime)
        
        guard let contentScale = attachments[.contentScaleKey] as? Double else {
            logger.error("Failed to get the contentScale from the sample buffer.")
            return
        }
        
        guard let scaleFactor = attachments[.scaleFactorKey] as? Double else {
            logger.error("Failed to get the scaleFactor from the sample buffer.")
            return
        }
        
        // Force-cast IOSurfaceRef to IOSurface.
        let surface = unsafeBitCast(surfaceRef, to: IOSurface.self)
        
        // Publish a new value for the latestFrame property.
        latestFrame = CapturedFrame(sampleBuffer: sampleBuffer,
                                    surface: surface,
                                    contentRect: contentRect,
                                    displayTime: elapsedTime,
                                    contentScale: contentScale,
                                    scaleFactor: scaleFactor)
    }
    
    private func convertToSeconds(_ machTime: UInt64) -> TimeInterval {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        let nanoseconds = machTime * UInt64(timebase.numer) / UInt64(timebase.denom)
        return Double(nanoseconds) / Double(kSecondScale)
    }
}

extension ScreenRecorder: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        logger.error("Stream stopped with error: \(error.localizedDescription)")
        self.error = error
        isRecording = false
    }
}
