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

struct CapturedFrame {
    var sampleBuffer: CMSampleBuffer
    var surface: IOSurface
    var contentRect: CGRect
    var displayTime: TimeInterval
    var contentScale: Double
    var scaleFactor: Double
}

class ScreenRecorder: NSObject, ObservableObject {
    
    struct ScreenRecorderError: Error {
        let errorDescription: String
        
        init(_ description: String) {
            errorDescription = description
        }
    }
    
    @MainActor @Published var latestFrame: CapturedFrame?
    @MainActor @Published var error: Error?
    @MainActor @Published var isRecording = false

    private var stream: SCStream?
    private let logger = Logger()
    private var cpuStartTime = mach_absolute_time()
    private let frameOutputQueue = DispatchQueue(label: "frame-handling")
    
    /// - Tag: StartCapture
    @MainActor
    func startCapture(with captureConfig: CaptureConfiguration) async {
        error = nil
        isRecording = false
        
        do {
            // Create the content filter with the sample app settings.
            let filter = try await contentFilter(for: captureConfig)
            
            // Create the stream configuration with the sample app settings.
            let streamConfig = streamConfiguration(for: captureConfig)
            
            // Create a capture stream with the filter and stream configuration.
            stream = SCStream(filter: filter, configuration: streamConfig, delegate: self)
            
            // Add a stream output to capture screen content.
            try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: frameOutputQueue)
            
            // Start the capture session.
            try await stream?.startCapture()
            
            cpuStartTime = mach_absolute_time()
            isRecording = true
        } catch {
            logger.error("Failed to start the stream session: \(String(describing: error))")
            self.error = error
        }
    }
    
    /// - Tag: UpdateCaptureConfig
    @MainActor
    func update(with captureConfig: CaptureConfiguration) async {
        do {
            let filter = try await contentFilter(for: captureConfig)
            let streamConfig = streamConfiguration(for: captureConfig)
            try await stream?.updateConfiguration(streamConfig)
            try await stream?.updateContentFilter(filter)
        } catch {
            logger.error("Failed to update the stream session: \(String(describing: error))")
            self.error = error
        }
    }
    
    @MainActor
    func stopCapture() async {
        isRecording = false
        
        do {
            try await stream?.stopCapture()
        } catch {
            logger.error("Failed to stop the stream session: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    /// - Tag: CreateContentFilter
    private func contentFilter(for config: CaptureConfiguration) async throws -> SCContentFilter {
        let filter: SCContentFilter
        
        if let display = config.display {

            // Create a content filter that includes all content from the display,
            // excluding the sample app's window.
            if config.filterOutOwningApplication {

                // Get the content that's available to capture.
                let content = try await SCShareableContent.excludingDesktopWindows(false,
                                                                                   onScreenWindowsOnly: true)
                
                // Exclude the sample app by matching the bundle identifier.
                let excludedApps = content.applications.filter { app in
                    Bundle.main.bundleIdentifier == app.bundleIdentifier
                }
                
                // Create a content filter that excludes the sample app.
                filter = SCContentFilter(display: display,
                                         excludingApplications: excludedApps,
                                         exceptingWindows: [])
                
            } else {
                // Create a content filter that includes the entire display.
                filter = SCContentFilter(display: display, excludingWindows: [])
            }
            
        } else if let window = config.window {
            
            // Create a content filter that includes a single window.
            filter = SCContentFilter(desktopIndependentWindow: window)
            
        } else {
            throw ScreenRecorderError("The configuration doesn't provide a display or window.")
        }
        return filter
    }
    
    /// - Tag: CreateStreamConfiguration
    private func streamConfiguration(for captureConfig: CaptureConfiguration) -> SCStreamConfiguration {
        let streamConfig = SCStreamConfiguration()
        
        // Set the capture size to twice the display size to support retina displays.
        if let display = captureConfig.display, captureConfig.captureType == .display {
            streamConfig.width = display.width * 2
            streamConfig.height = display.height * 2
        }
        
        // Set the capture interval at 60 fps.
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(60))
        
        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        streamConfig.queueDepth = 5
        
        return streamConfig
    }
    
    private func convertToSeconds(_ machTime: UInt64) -> TimeInterval {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        let nanoseconds = machTime * UInt64(timebase.numer) / UInt64(timebase.denom)
        return Double(nanoseconds) / Double(kSecondScale)
    }
}

extension ScreenRecorder: SCStreamOutput {
        
    /// - Tag: DidOutputSampleBuffer
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {

        guard sampleBuffer.isValid else {
            logger.log("The sample buffer is invalid.")
            return
        }

        // Retrieve the dictionary of metadata attachments from the sample buffer.
        // You use the attachments to retrieve data about the captured frame.
        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true) as? [[SCStreamFrameInfo: Any]],
              let attachments = attachmentsArray.first else {
            logger.error("Failed to retrieve the attachments from the sample buffer.")
            return
        }

        guard let statusRawValue = attachments[SCStreamFrameInfo.status] as? Int,
              let status = SCFrameStatus(rawValue: statusRawValue) else {
            logger.error("Failed to get the frame status from the attachments.")
            return
        }
        
        guard status == .complete else {
            logger.log("Skip updating the frame because the frame status is \(String(describing: status))")
            return
        }

        guard let pixelBuffer = sampleBuffer.imageBuffer else {
            logger.error("Failed to get a pixel buffer from the sample buffer.")
            return
        }

        guard let surfaceRef = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else {
            logger.error("Could not get an IOSurface from the pixel buffer.")
            return
        }

        guard let contentRectDict = attachments[.contentRect],
              let contentRect = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary) else {
            logger.error("Failed to get a content rectangle from the sample buffer.")
            return
        }

        guard let displayTime = attachments[.displayTime] as? UInt64 else {
            logger.error("Failed to get a display time from the sample buffer.")
            return
        }

        let elapsedTime = convertToSeconds(displayTime) - convertToSeconds(cpuStartTime)

        guard let contentScale = attachments[.contentScale] as? Double else {
            logger.error("Failed to get the contentScale from the sample buffer.")
            return
        }

        guard let scaleFactor = attachments[.scaleFactor] as? Double else {
            logger.error("Failed to get the scaleFactor from the sample buffer.")
            return
        }

        // Force-cast the IOSurfaceRef to IOSurface.
        let surface = unsafeBitCast(surfaceRef, to: IOSurface.self)
        
        // Publish the new captured frame.
        DispatchQueue.main.async {
            self.latestFrame = CapturedFrame(sampleBuffer: sampleBuffer,
                                             surface: surface,
                                             contentRect: contentRect,
                                             displayTime: elapsedTime,
                                             contentScale: contentScale,
                                             scaleFactor: scaleFactor)
        }
    }
}

extension ScreenRecorder: SCStreamDelegate {
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        DispatchQueue.main.async {
            self.logger.error("Stream stopped with error: \(error.localizedDescription)")
            self.error = error
            self.isRecording = false
        }
    }
}
