# Capturing Screen Content in macOS
Stream desktop content like displays, apps, and windows by adopting screen capture in your app.

## Overview
This sample shows how to add high-performance screen capture to your Mac app by using [`ScreenCaptureKit`][7]. The sample explores how to create a content filter to capture the displays, apps, and windows you choose. It then shows how to configure your stream output, retrieve video frames, and update the stream.
  

## Configure the Sample Code Project
To run this sample app, you’ll need the following:

- A Mac with macOS 12.3 beta or later
- Xcode 13.3 beta or later

The first time you run this sample, the system prompts you to grant the app Screen Recording permission. After you grant permission, you need to restart the app to enable capture. 

## Create a Content Filter
Sharable content represents displays, running applications, and windows on a device. The sample uses [`SCSharableContent`][8] to get the available content as lists of [`SCDisplay`][9], [`SCRunningApplication`][10], and [`SCWindow`][11].

``` swift
availableContent = try await SCShareableContent.excludingDesktopWindows(false,
                                                                        onScreenWindowsOnly: true)
```
[View in Source][1]

Before the sample captures content, it creates an [`SCContentFilter`][12] object to specify the content to capture. The sample provides two options that allow for capturing either an independent window or an entire display. When the capture type is set to an independent window, the app creates a content filter that only includes that window.

``` swift
// Create a content filter that includes a single window.
filter = SCContentFilter(desktopIndependentWindow: window)
```
[View in Source][2]

If the capture type is set to entire display, the sample creates a filter to capture the display. To illustrate filtering a running app, the sample contains a toggle to specify whether to include the sample app in the stream.

``` swift
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
```
[View in Source][2]

## Configure the Stream Capture Session
An [`SCStreamConfiguration`][13] object provides properties to configure output width, height, pixel format, and more. The sample's configuration throttles frame updates to 60 fps, and configures the number of frames to keep in the queue at 5. Specifying more frames uses more memory, but may allow for processing frame data without stalling the display stream. The default value is 3 and shouldn't exceed 8 frames.

``` swift
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
```
[View in Source][3] 

## Start the Capture Session
After creating the output settings for the content stream, the sample creates an [`SCStream`][14] object. To retrieve the frame data, the sample adds a stream output that specifies the [`DispatchQueue`][15] that handles the output. It then starts the capture session.

``` swift
// Create a capture stream with the filter and stream configuration.
stream = SCStream(filter: filter, configuration: streamConfig, delegate: self)

// Add a stream output to capture screen content.
try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: frameOutputQueue)

// Start the capture session.
try await stream?.startCapture()
```
[View in Source][4]

## Inspect the Sample Buffer
The [`SCStreamOutput`][16] protocol provides a callback that the system calls when a [`CMSampleBuffer`][17] is available. When the system provides a valid buffer, the sample inspects it to retrieve attachment information about the frame.  

``` swift
guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true) as? [[SCStreamFrameInfo: Any]],
      let attachments = attachmentsArray.first else {
    logger.error("Failed to retrieve the attachments from the sample buffer.")
    return
}
```
[View in Source][5]

An [`SCStreamFrameInfo`][18] structure defines dictionary keys that the sample uses to retrieve metadata attached to a sample buffer. Metadata includes information about the frame's display time, scale factor, status, and more. To determine whether a frame is available for processing, the sample inspects status for [`SCFrameStatus.complete`][19].

``` swift
guard let statusRawValue = attachments[SCStreamFrameInfo.status] as? Int,
      let status = SCFrameStatus(rawValue: statusRawValue) else {
    logger.error("Failed to get the frame status from the attachments.")
    return
}

guard status == .complete else {
    logger.log("Skip updating the frame because the frame status is \(String(describing: status))")
    return
}
```
[View in Source][5]

The sample buffer wraps a [`CVPixelBuffer`][20] that’s backed by an [`IOSurface`][21]. 

``` swift
guard let pixelBuffer = sampleBuffer.imageBuffer else {
    logger.error("Failed to get a pixel buffer from the sample buffer.")
    return
}

guard let surfaceRef = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else {
    logger.error("Could not get an IOSurface from the pixel buffer.")
    return
}
```
[View in Source][5]

The sample casts the surface reference to an `IOSurface` to set the layer content of an [`NSView`][22].

``` swift
// Force-cast the IOSurfaceRef to IOSurface.
let surface = unsafeBitCast(surfaceRef, to: IOSurface.self)
```
[View in Source][5]

## Update Configuration and Content Filter

The sample doesn't stop the capture session to update the configuration or filter. After creating new output settings, it calls the update methods on the `SCStream` object.

``` swift
try await stream?.updateConfiguration(streamConfig)
try await stream?.updateContentFilter(filter)
```
[View in Source][6]

## Stop the Capture Session
End the capture session by calling [`stopCapture(completionHandler:)`][23] on the `SCStream` object. The sample adopts [`SCStreamDelegate`][24] and receives a callback if the capture session ends with an error.

``` swift
func stream(_ stream: SCStream, didStopWithError error: Error) {
    DispatchQueue.main.async {
        self.logger.error("Stream stopped with error: \(error.localizedDescription)")
        self.error = error
        self.isRecording = false
    }
}
```


[1]: x-source-tag://GetAvailableContent
[2]: x-source-tag://CreateContentFilter
[3]: x-source-tag://CreateStreamConfiguration
[4]: x-source-tag://StartCapture
[5]: x-source-tag://DidOutputSampleBuffer
[6]: x-source-tag://UpdateCaptureConfig
[7]: https://developer.apple.com/documentation/screencapturekit
[8]: https://developer.apple.com/documentation/screencapturekit/scshareablecontent
[9]: https://developer.apple.com/documentation/screencapturekit/scdisplay
[10]: https://developer.apple.com/documentation/screencapturekit/scrunningapplication
[11]: https://developer.apple.com/documentation/screencapturekit/scwindow
[12]: https://developer.apple.com/documentation/screencapturekit/sccontentfilter
[13]: https://developer.apple.com/documentation/screencapturekit/scstreamconfiguration
[14]: https://developer.apple.com/documentation/screencapturekit/scstream
[15]: https://developer.apple.com/documentation/dispatch/dispatchqueue
[16]: https://developer.apple.com/documentation/screencapturekit/scstreamoutput
[17]: https://developer.apple.com/documentation/coremedia/cmsamplebuffer-u71
[18]: https://developer.apple.com/documentation/screencapturekit/scstreamframeinfo
[19]: https://developer.apple.com/documentation/screencapturekit/scframestatus/complete
[20]: https://developer.apple.com/documentation/corevideo/cvpixelbuffer-q2e
[21]: https://developer.apple.com/documentation/iosurface
[22]: https://developer.apple.com/documentation/appkit/nsview
[23]: https://developer.apple.com/documentation/screencapturekit/scstream/3928172-stopcapture
[24]: https://developer.apple.com/documentation/screencapturekit/scstreamdelegate
