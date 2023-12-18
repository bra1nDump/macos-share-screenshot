//
//  ShareShot-Bridging-Header.h
//  CaptureSample
//
//  Created by Kirill Dubovitskiy on 12/17/23.
//  Copyright © 2023 Apple. All rights reserved.
//

#ifndef ShareShot_Bridging_Header_h
#define ShareShot_Bridging_Header_h

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ApplicationServices/ApplicationServices.h>

#import "ShowAndHideCursor.h"

//typedef int CGSConnectionID;
//CGError CGSSetConnectionProperty(CGSConnectionID cid, CGSConnectionID targetCID, CFStringRef key, CFTypeRef value);
//int _CGSDefaultConnection();

void cHideCursor(void) {
    void CGSSetConnectionProperty(int, int, CFStringRef, CFBooleanRef);
    int _CGSDefaultConnection(void);
    CFStringRef propertyString;
    
    // Hack to make background cursor setting work
    propertyString = CFStringCreateWithCString(NULL, "SetsCursorInBackground", kCFStringEncodingUTF8);
    CGSSetConnectionProperty(_CGSDefaultConnection(), _CGSDefaultConnection(), propertyString, kCFBooleanTrue);
    CFRelease(propertyString);
    // Hide the cursor and wait
    CGDisplayHideCursor(kCGDirectMainDisplay);
}

void cShowCursor(void) {
    CGDisplayShowCursor(kCGDirectMainDisplay);
}


#endif /* ShareShot_Bridging_Header_h */
