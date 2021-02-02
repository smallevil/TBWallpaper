//
//  NSImage+Blur.m
//  Test
//
//  Created by Nuoxici  on 2019/4/3.
//  Copyright © 2019 Nuoxici. All rights reserved.
//

#import "NSImage+Blur.h"
#import <CoreImage/CIFilter.h>

@implementation NSImage (Blur)

- (NSImage *)blur:(CGFloat)aRadius
{
    NSImage *image = self;
    
    [image lockFocus];
    CIImage *beginImage = [[CIImage alloc] initWithData:[image TIFFRepresentation]];
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur" keysAndValues:kCIInputImageKey, beginImage, @"inputRadius", @(aRadius), nil];
    CIImage *output = [filter valueForKey:@"outputImage"];
    NSRect rect = NSMakeRect(0, 0, self.size.width, self.size.height);
    NSRect sourceRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    [output drawInRect:rect fromRect:sourceRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [image unlockFocus];
    return image;
}

- (NSImage *)resize:(NSSize)newSize  bigScaleStatus:(BOOL)bigScaleStatus
{
    NSImage *sourceImage = self;
    //[sourceImage setScalesWhenResized:YES];
    
    float oriImgWidth = sourceImage.size.width;
    float oriImgHeight = sourceImage.size.height;
    float widthScale = 1.0 * newSize.width / oriImgWidth;
    float heightScale = 1.0 * newSize.height / oriImgHeight;
    float scale;
    if(bigScaleStatus)
    {
        if(widthScale > heightScale)
        {
            scale = widthScale;
        }
        else
        {
            scale = heightScale;
        }
    }
    else
    {
        if(widthScale < heightScale)
        {
            scale = widthScale;
        }
        else
        {
            scale = heightScale;
        }
    }
    int resizeImgWidth = (int)(scale * oriImgWidth);
    int resizeImgHeight = (int)(scale * oriImgHeight);
    
    NSLog(@"resize %dx%d", resizeImgWidth, resizeImgHeight);
    
    NSImage *objImage = [[NSImage alloc] initWithSize: CGSizeMake(resizeImgWidth, resizeImgHeight)];
    [objImage lockFocus];
    [sourceImage setSize: CGSizeMake(resizeImgWidth, resizeImgHeight)];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [sourceImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, resizeImgWidth, resizeImgHeight) operation:NSCompositingOperationCopy fraction:1.0];
    [objImage unlockFocus];
    
    return objImage;
}

-(NSImage *)sliceImage:(NSRect)srcRect
{
    NSImage *image = self;
    NSRect targetRect = NSMakeRect(0, 0, srcRect.size.width, srcRect.size.height);

    NSImage *result = [[NSImage alloc] initWithSize:targetRect.size];

    [result lockFocus];

    [image drawInRect:targetRect fromRect:srcRect operation:NSCompositingOperationCopy fraction:1.0];

    [result unlockFocus];

    return result;
}

- (NSImage *)roundImage:(int)Radius
{
    NSImage *image = self;
    NSImage *existingImage = image;
    NSSize existingSize = [existingImage size];
    NSSize newSize = NSMakeSize(existingSize.width, existingSize.height);
    NSImage *composedImage = [[NSImage alloc] initWithSize:newSize];

    [composedImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

    NSRect imageFrame = NSRectFromCGRect(CGRectMake(0, 0, image.size.width, image.size.height));
    NSBezierPath *clipPath = [NSBezierPath bezierPathWithRoundedRect:imageFrame xRadius:Radius yRadius:Radius];
    [clipPath setWindingRule:NSEvenOddWindingRule];
    [clipPath addClip];

    [image drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0, 0, newSize.width, newSize.height) operation:NSCompositingOperationSourceOver fraction:1.0];

    [composedImage unlockFocus];

    return composedImage;
}

- (NSImage *)merge:(NSImage *)overlay
{
    
    //Get the source image from file
    NSImage *source = overlay; //[[NSImage alloc]initWithContentsOfFile:@"/Users/JensThomsen/Library/Developer/Xcode/DerivedData/Smartphone_App_Store_Icons_and_Images_Tool-bsnfzaaviuzrqdcpuknipijqslci/Build/Products/Debug/icon512.png"];
    
    //Init target image
    NSImage *target = self; //[[NSImage alloc]initWithContentsOfFile:@"/Users/JensThomsen/Library/Developer/Xcode/DerivedData/Smartphone_App_Store_Icons_and_Images_Tool-bsnfzaaviuzrqdcpuknipijqslci/Build/Products/Debug/tempImage.png"];
    
    //start drawing on target
    [target lockFocus];
    //draw the portion of the source image on target image
    [source drawInRect:NSMakeRect((target.size.width - source.size.width) / 2, (target.size.height - source.size.height) / 2, source.size.width, source.size.height) fromRect:NSZeroRect operation: NSCompositingOperationSourceOver fraction:1.0];
    //end drawing
    [target unlockFocus];
    
    //create a NSBitmapImageRep
    NSBitmapImageRep *bmpImageRep = [[NSBitmapImageRep alloc] initWithData:[target TIFFRepresentation]];
    //add the NSBitmapImage to the representation list of the target
    [target addRepresentation:bmpImageRep];


    return target;
}

- (BOOL)isScaleBy16_9
{
    if(self.size.width < self.size.height)
    {
        //竖图
        return NO;
    }
    
    NSScreen* thescreen;
    id theScreens = [NSScreen screens];
    for (thescreen in theScreens)
    {
        if(self.size.height < [thescreen frame].size.height || self.size.width < [thescreen frame].size.width)
        {
            return NO;
        }
        else
        {
            //你将宽度数除以16再乘以9，如果得到的数字和高的一样（或者差不多)
            if(self.size.height * 0.98 < self.size.width / 16.0 * 9 < self.size.height * 1.02)
            {
                return YES;
            }
            else
            {
                return NO;
            }
        }
    }
    
    return NO;
    
    /*
    if(self.size.width * 0.8 < self.size.width * 9.0 / 16 < self.size.height * 1.5 && MIN(self.size.width, self.size.height) > MIN(1440, 900) * 0.8)
    {
        return YES;
    }
    else
    {
        return NO;
    }
     */
}
@end
