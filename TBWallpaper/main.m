//
//  main.m
//  TBWallpaper
//
//  Created by 吴韵卫 on 2021/1/22.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
    }
    
    NSApplication *app = [NSApplication sharedApplication];
    id delegate = [[AppDelegate alloc] init];
    app.delegate = delegate;
    
    return NSApplicationMain(argc, argv);
}
