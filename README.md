# Capturing screen content in macOS
Stream desktop content like displays, apps, and windows by adopting screen capture in your app.

## Overview
This sample shows how to add high-performance screen capture to your Mac app by using [`ScreenCaptureKit`][1]. The sample explores how to create content filters to capture the displays, apps, and windows you choose. It then shows how to configure your stream output, retrieve video frames and audio samples, and update a running stream.
- Note: This sample code project is associated with WWDC22 sessions [10156: Meet ScreenCaptureKit](https://developer.apple.com/wwdc22/10156) and [10155: Take ScreenCaptureKit to the next level](https://developer.apple.com/wwdc22/10155)

## Configure the sample code project
To run this sample app, you’ll need the following:

- A Mac with macOS 13 beta or later
- Xcode 14 beta or later

The first time you run this sample, the system prompts you to grant the app Screen Recording permission. After you grant permission, you need to restart the app to enable capture. 

## Create a content filter
Displays, running apps, and windows are the shareable content on a device. The sample uses the [`SCShareableContent`][2] class to retrieve the items in the form of [`SCDisplay`][3], [`SCRunningApplication`][4], and [`SCWindow`][5] objects respectively.

``` swift
// Retrieve the available screen content to capture.
let availableContent = try await SCShareableContent.excludingDesktopWindows(false,
                                                                            onScreenWindowsOnly: true)
```
[View in Source][6]

Before the sample begins capture, it creates an [`SCContentFilter`][7] object to specify the content to capture. The sample provides two options that allow for capturing either a single window or an entire display. When the capture type is set to capture a window, the app creates a content filter that only includes that window. 

``` swift
// Create a content filter that includes a single window.
filter = SCContentFilter(desktopIndependentWindow: window)
```
[View in Source][8]
When a user specifies to capture the entire display, the sample creates a filter to capture only content from the main display. To illustrate filtering a running app, the sample contains a toggle to specify whether to exclude the sample app from the stream.

``` swift
var excludedApps = [SCRunningApplication]()
// If a user chooses to exclude the app from the stream,
// exclude it by matching its bundle identifier.
if isAppExcluded {
    excludedApps = availableApps.filter { app in
        Bundle.main.bundleIdentifier == app.bundleIdentifier
    }
}
// Create a content filter with excluded apps.
filter = SCContentFilter(display: display,
                         excludingApplications: excludedApps,
                         exceptingWindows: [])
```
[View in Source][9]

## Create a stream configuration
An [`SCStreamConfiguration`][10] object provides properties to configure the stream’s output size, pixel format, audio capture settings, and more. The app’s configuration throttles frame updates to 60 fps, and configures the number of frames to keep in the queue at 5. Specifying more frames uses more memory, but may allow for processing frame data without stalling the display stream. The default value is 3 and shouldn't exceed 8 frames.

``` swift
let streamConfig = SCStreamConfiguration()

// Configure audio capture.
streamConfig.capturesAudio = isAudioCaptureEnabled
streamConfig.excludesCurrentProcessAudio = isAppAudioExcluded

// Configure the display content width and height.
if captureType == .display, let display = selectedDisplay {
    streamConfig.width = display.width * scaleFactor
    streamConfig.height = display.height * scaleFactor
}

// Configure the window content width and height.
if captureType == .window, let window = selectedWindow {
    streamConfig.width = Int(window.frame.width) * 2
    streamConfig.height = Int(window.frame.height) * 2
}

// Set the capture interval at 60 fps.
streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 60)

// Increase the depth of the frame queue to ensure high fps at the expense of increasing
// the memory footprint of WindowServer.
streamConfig.queueDepth = 5
```
[View in Source][11] 

## Start the capture session
The sample uses the content filter and stream configuration to initialize a new instance of `SCStream`. To retrieve audio and video sample data, the app adds stream outputs that capture media of the specified type. When the stream captures new sample buffers, it delivers them to its stream output object on the indicated dispatch queues.

``` swift
stream = SCStream(filter: filter, configuration: configuration, delegate: streamOutput)

// Add a stream output to capture screen content.
try stream?.addStreamOutput(streamOutput, type: .screen, sampleHandlerQueue: videoSampleBufferQueue)
try stream?.addStreamOutput(streamOutput, type: .audio, sampleHandlerQueue: audioSampleBufferQueue)
stream?.startCapture()
```
[View in Source][12]

After the stream starts, further changes to its configuration and content filter don’t require restarting it. Instead, after you update the capture configuration in the user interface, the sample creates new stream configuration and content filter objects and applies them to the running stream to update its state.
``` swift
try await stream?.updateConfiguration(configuration)
try await stream?.updateContentFilter(filter)
```
[View in Source][13]

## Process the output
When a stream captures a new audio or video sample buffer, it calls the stream output’s [stream(\_:didOutputSampleBuffer:of:)][14] method, passing it the captured data and an indicator of its type. The stream output evaluates and processes the sample buffer as shown below.
``` swift
func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
    
    // Return early if the sample buffer is invalid.
    guard sampleBuffer.isValid else { return }
    
    // Determine which type of data the sample buffer contains.
    switch outputType {
    case .screen:
		// Process the screen content.
    case .audio:
		// Process the audio content.
    }
}
```

## Process a video sample buffer
If the sample buffer contains video data, it retrieves the sample buffer attachments that describe the output video frame.  

``` swift
// Retrieve the array of metadata attachments from the sample buffer.
guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer,
                                                                     createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
      let attachments = attachmentsArray.first else { return nil }
```
[View in Source][15]

An [`SCStreamFrameInfo`][16] structure defines dictionary keys that the sample uses to retrieve metadata attached to a sample buffer. Metadata includes information about the frame's display time, scale factor, status, and more. To determine whether a frame is available for processing, the sample inspects the status for [`SCFrameStatus.complete`][17].

``` swift
// Validate the status of the frame. If it isn't `.complete`, return nil.
guard let statusRawValue = attachments[SCStreamFrameInfo.status] as? Int,
      let status = SCFrameStatus(rawValue: statusRawValue),
      status == .complete else { return nil }
```
[View in Source][18]

The sample buffer wraps a [`CVPixelBuffer`][19] that’s backed by an [`IOSurface`][20]. The sample casts the surface reference to an `IOSurface` that it later sets as the layer content of an [`NSView`][21].

``` swift
// Get the pixel buffer that contains the image data.
guard let pixelBuffer = sampleBuffer.imageBuffer else { return nil }

// Get the backing IOSurface.
guard let surfaceRef = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else { return nil }
let surface = unsafeBitCast(surfaceRef, to: IOSurface.self)

// Retrieve the content rectangle, scale, and scale factor.
guard let contentRectDict = attachments[.contentRect],
      let contentRect = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary),
      let contentScale = attachments[.contentScale] as? CGFloat,
      let scaleFactor = attachments[.scaleFactor] as? CGFloat else { return nil }

// Create a new frame with the relevant data.
let frame = CapturedFrame(surface: surface,
                          contentRect: contentRect,
                          contentScale: contentScale,
                          scaleFactor: scaleFactor)
```
[View in Source][22]

## Process an audio sample buffer
If the sample buffer contains audio, it retrieves the data as an [AudioBufferList][23] as shown below.  

``` swift
private func createPCMBuffer(for sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {
    var ablPointer: UnsafePointer<AudioBufferList>?
    try? sampleBuffer.withAudioBufferList { audioBufferList, blockBuffer in
        ablPointer = audioBufferList.unsafePointer
    }
    guard let audioBufferList = ablPointer,
          let absd = sampleBuffer.formatDescription?.audioStreamBasicDescription,
          let format = AVAudioFormat(standardFormatWithSampleRate: absd.mSampleRate, channels: absd.mChannelsPerFrame) else { return nil }
    return AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: audioBufferList)
}
```
[View in Source][24]

The app retrieves the audio stream basic description that it uses to create an [AVAudioFormat][25]. It then uses the format and the audio buffer list to create a new instance of [AVAudioPCMBuffer][26]. If you enable audio capture in the user interface, the sample uses the buffer to calculate average levels for the captured audio to display in a simple level meter.

[1]:	https://developer.apple.com/documentation/screencapturekit
[2]:	https://developer.apple.com/documentation/screencapturekit/scshareablecontent
[3]:	https://developer.apple.com/documentation/screencapturekit/scdisplay
[4]:	https://developer.apple.com/documentation/screencapturekit/scrunningapplication
[5]:	https://developer.apple.com/documentation/screencapturekit/scwindow
[6]:	x-source-tag://GetAvailableContent
[7]:	https://developer.apple.com/documentation/screencapturekit/sccontentfilter
[8]:	x-source-tag://UpdateFilter
[9]:	x-source-tag://UpdateFilter
[10]:	https://developer.apple.com/documentation/screencapturekit/scstreamconfiguration
[11]:	x-source-tag://CreateStreamConfiguration
[12]:	x-source-tag://StartCapture
[13]:	x-source-tag://UpdateStreamConfiguration
[14]:	https://developer.apple.com/documentation/screencapturekit/scstreamoutput/3928182-stream
[15]:	x-source-tag://DidOutputSampleBuffer
[16]:	https://developer.apple.com/documentation/screencapturekit/scstreamframeinfo
[17]:	https://developer.apple.com/documentation/screencapturekit/scframestatus/complete
[18]:	x-source-tag://DidOutputSampleBuffer
[19]:	https://developer.apple.com/documentation/corevideo/cvpixelbuffer-q2e
[20]:	https://developer.apple.com/documentation/iosurface
[21]:	https://developer.apple.com/documentation/appkit/nsview
[22]:	x-source-tag://DidOutputSampleBuffer
[23]:	https://developer.apple.com/documentation/coreaudiotypes/audiobufferlist
[24]:	x-source-tag://ProcessAudioSampleBuffer
[25]:	https://developer.apple.com/documentation/avfaudio/avaudioformat
[26]:	https://developer.apple.com/documentation/avfaudio/avaudiopcmbuffer