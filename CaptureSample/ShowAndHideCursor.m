//
//  ShowAndHideCursor.m
//  CaptureSample
//
//  Created by Kirill Dubovitskiy on 12/17/23.
//  Copyright © 2023 Apple. All rights reserved.
//

#include "ShowAndHideCursor.h"

// Unfortunately `kCGDirectMainDisplay` is unavailable in Swift.
CGDirectDisplayID kCGDirectMainDisplayGetter(void) {
    return kCGDirectMainDisplay;
}

