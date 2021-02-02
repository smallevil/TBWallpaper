//
//  NSImage+Blur.h
//  Test
//
//  Created by Nuoxici on 2019/4/3.
//  Copyright © 2019 Nuoxici. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSImage (Blur)
- (NSImage *)blur:(CGFloat)aRadius;
- (NSImage *)resize:(NSSize)newSize bigScaleStatus:(BOOL)bigScaleStatus;
- (NSImage *)roundImage:(int)Radius;
- (NSImage *)merge:(NSImage *)overlay;
- (NSImage *)sliceImage:(NSRect)srcRect;
- (BOOL)isScaleBy16_9;
@end

NS_ASSUME_NONNULL_END
