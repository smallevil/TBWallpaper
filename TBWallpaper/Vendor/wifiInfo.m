//
//  wifiInfo.m
//  TBWallpaper
//
//  Created by 吴韵卫 on 2021/1/23.
//

#import "wifiInfo.h"

@implementation wifiInfo

+(NSDictionary*)getWifiBSSID
{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport";
    NSArray *arguments = [NSArray arrayWithObjects:@"-I", nil];
    task.arguments = arguments;
    
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    NSFileHandle *file = [pipe fileHandleForReading];
    [task launch];
    NSData *data = [file readDataToEndOfFile];
    NSString *retval = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    //NSLog(@"%@", retval);
    
    NSMutableDictionary *wifi = [[NSMutableDictionary alloc] init];
    [wifi setValue:@"" forKey:@"bssid"];
    [wifi setValue:@"" forKey:@"ssid"];
    
    if([retval rangeOfString:@"BSSID"].location != NSNotFound)
    {
        NSArray *lines = [retval componentsSeparatedByString:@"\n"];
        for(NSString *line in lines)
        {
            if([line rangeOfString:@"BSSID"].location != NSNotFound)
            {
                NSString *bssid = [line substringFromIndex:NSMaxRange([line rangeOfString:@"BSSID:"])];
                bssid = [bssid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                bssid = [bssid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet ]];
                NSLog(@"bssid:%@", bssid);
                
                wifi[@"bssid"] = bssid;
            }
            
            if([line rangeOfString:@"SSID"].location != NSNotFound && [line rangeOfString:@"BSSID"].location == NSNotFound)
            {
                NSString *ssid = [line substringFromIndex:NSMaxRange([line rangeOfString:@"SSID:"])];
                ssid = [ssid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                ssid = [ssid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet ]];
                NSLog(@"ssid:%@", ssid);
                
                wifi[@"ssid"] = ssid;
            }
        }
    }
    
    return [wifi copy];
    
}

@end
