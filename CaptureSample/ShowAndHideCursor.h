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

// Unfortunately `kCGDirectMainDisplay` is unavailable in Swift.
CGDirectDisplayID kCGDirectMainDisplayGetter(void);

void cHideCursor(void);

#endif /* ShowAndHideCursor_h */

