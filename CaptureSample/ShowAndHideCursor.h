//
//  ShowAndHideCursor.h
//  CaptureSample
//
//  Created by Kirill Dubovitskiy on 12/17/23.
//  Copyright © 2023 Apple. All rights reserved.
//

#ifndef ShowAndHideCursor_h
#define ShowAndHideCursor_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ApplicationServices/ApplicationServices.h>

// Source: https://stackoverflow.com/a/3939241/5278310
// And https://github.com/acheronfail/pixel-picker/blob/fae1ec38c938d625b5122aa5cbc497c9ef6effc1/Pixel%20Picker/ShowAndHideCursor.swift
//
// Related
// https://developer.apple.com/documentation/coregraphics/1454426-cgeventtapcreate

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


#endif /* ShowAndHideCursor_h */

