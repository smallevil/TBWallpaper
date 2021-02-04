#import "NSScreen+DisplayInfo.h"
#import <IOKit/graphics/IOGraphicsLib.h>

@implementation NSScreen (DisplayInfo)

-(NSString*) displayName
{
    CGDirectDisplayID displayID = [[self displayID] intValue];

    NSString *screenName = nil;

    NSDictionary *deviceInfo = (NSDictionary *)CFBridgingRelease(IODisplayCreateInfoDictionary(CGDisplayIOServicePort(displayID), kIODisplayOnlyPreferredName));
    NSDictionary *localizedNames = [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];

    if ([localizedNames count] > 0) {
        screenName = [localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]];
    }

    return screenName;
}

-(NSNumber*) displayID
{
    return [[self deviceDescription] valueForKey:@"NSScreenNumber"];
}
@end