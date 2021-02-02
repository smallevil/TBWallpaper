//
//  AppDelegate.m
//  TBWallpaper
//
//  Created by 吴韵卫 on 2021/1/22.
//

#import "AppDelegate.h"
#import "WPSettingView.h"
#import <CoreWLAN/CoreWLAN.h>
#import "wifiInfo.h"
#import "TBHelper.h"
#import "NSImage+Blur.h"
#include <CoreAudio/CoreAudio.h>
#include <AudioToolbox/AudioServices.h>

#include "Reachability.h"


@interface AppDelegate ()

@property (nonatomic,strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSPopover *popover;

@property (nonatomic, strong) NSMutableDictionary *imageFiles;

@property (nonatomic, assign) NSTimer *changeTimer;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    //[TBHelper delValueFromUserDefaults:@"wp_infos"];
    
    [self addStatusBar];
    [self setGlobalHotKey];
    [self settingInit];
    
}

-(void)setGlobalHotKey
{
    /*
    NSDictionary* opts = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    if(AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)opts))
    {
        NSLog(@"Accessibility Enabled");
    }
    else
    {
        NSLog(@"Accessibility Disabled");
    }
     */
    
    [NSEvent addGlobalMonitorForEventsMatchingMask:(NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown)  handler:^(NSEvent * event) {
        //NSUInteger ctrlPressed  = [event modifierFlags] & NSEventModifierFlagControl;
        //NSUInteger optionPressed = [event modifierFlags] & NSEventModifierFlagOption;
        NSUInteger cmdPressed   = [event modifierFlags] & NSEventModifierFlagCommand;
        
        if(cmdPressed && [event clickCount] == 3)
        {
            NSLog(@"command+鼠标连续3次点击");
            
            if([TBHelper getValueFromUserDefaults:@"important_status"])
            {
                if([[TBHelper getValueFromUserDefaults:@"important_status"] integerValue])
                {
                    [TBHelper setValueFromUserDefaults:@"important_status" value:@"0"];
                }
                else
                {
                    [TBHelper setValueFromUserDefaults:@"important_status" value:@"1"];
                }
            }
            else
            {
                [TBHelper setValueFromUserDefaults:@"important_status" value:@"1"];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Change_Wallpaper" object:nil userInfo:nil];
        }
        
    }];
}

 

- (void)addStatusBar
{
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    NSStatusItem *statusItem = [statusBar statusItemWithLength: NSSquareStatusItemLength];
    self.statusItem = statusItem;
    
    statusItem.button.image = [NSImage imageNamed:@"bar"];
    statusItem.button.imagePosition = NSImageLeft;
    statusItem.button.toolTip = @"壁纸";
    
    [statusItem.button setTarget:self];
    [statusItem.button setAction:@selector(showPopover:)];
    
    /*
    //菜单
    NSMenu *subMenu = [[NSMenu alloc] initWithTitle:@"Load_TEXT"];
    [subMenu addItemWithTitle:@"设置"action:@selector(setApp) keyEquivalent:@"S"];
    [subMenu addItemWithTitle:@"退出"action:@selector(exitApp) keyEquivalent:@"Q"];
    statusItem.menu = subMenu;
    */
    NSLog(@"机器名:%@", [[NSHost currentHost] localizedName]);
    NSLog(@"登录名:%@  全名:%@", NSUserName(), NSFullUserName());
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    [statusBar removeStatusItem:self.statusItem];
    
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
        return NO;//YES-窗口程序两者都关闭，NO-只关闭窗口；
}

-(void) setUpPopover {
    self.popover = [[NSPopover alloc] init];
    self.popover.contentViewController = [[WPSettingView alloc] initWithNibName:@"WPSettingView" bundle:nil];
    self.popover.behavior = NSPopoverBehaviorApplicationDefined;
    self.popover.behavior = NSPopoverBehaviorTransient;
    self.popover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
    
    
    // 防止下面的block方法中造成循环引用
    __weak typeof (self) weakSelf = self;
    // 添加对鼠标左键进行事件监听
    // 如果想对其他事件监听也进行监听，可以修改第一个枚举参数： NSEventMaskLeftMouseDown | 你要监听的其他枚举值
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown handler:^(NSEvent * event) {
        if (weakSelf.popover.isShown) {
            // 关闭popover；
            [weakSelf.popover close];
        }
    }];
     
}

- (void)showPopover:(NSStatusBarButton *)button{
    if(!self.popover)
    {
        [self setUpPopover];
    }
    
    [self.popover showRelativeToRect:button.bounds ofView:button preferredEdge:NSRectEdgeMaxY];
}

- (void)exitApp{
    [[NSApplication sharedApplication] terminate:self];
}

////////////////////////////////////////////////////////////监听屏幕/////////////////////////////////

- (void) receiveSleepNote: (NSNotification*) note
{
    //此函数会被多次触发
    
    
    //关机(休眠)时直接设成默认壁纸
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Change_Wallpaper" object:@{@"status":@"default"} userInfo:nil];   //切换网络时
    
    //关机(休眠)时直接设成最小声音
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Change_volume" object:@{@"type":@"small"} userInfo:nil];
    NSLog(@"receiveSleepNote: %@", [note name]);
}
 
- (void) receiveWakeNote: (NSNotification*) note
{
    //此函数会被多次触发
    
    NSLog(@"receiveWakeNote: %@", [note name]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Change_Wallpaper" object:nil userInfo:nil];   //切换网络时
}

-(void)settingInit
{
    NSInteger changeTime;
    if([TBHelper getValueFromUserDefaults:@"wp_change_time"])
    {
        changeTime = [[TBHelper getValueFromUserDefaults:@"wp_change_time"] integerValue];
    }
    else
    {
        [TBHelper setValueFromUserDefaults:@"wp_change_time" value:@"10"];
        changeTime = 10;
    }
    
    [_changeTimer invalidate];
    _changeTimer = nil;
    _changeTimer = [NSTimer scheduledTimerWithTimeInterval:changeTime * 60 target:self selector:@selector(setWallpaperTimer) userInfo:nil repeats:YES];
    
    _imageFiles = [[NSMutableDictionary alloc] init];
    [self updateImageFiles];    //启动时搜索一次图片
    [NSTimer scheduledTimerWithTimeInterval:3600 * 1 target:self selector:@selector(updateImageFiles) userInfo:nil repeats:YES];    //每1小时更新一次
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateImageFiles) name:@"Notification_Update_Images" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setWallpaper:) name:@"Notification_Change_Wallpaper" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setVolume:) name:@"Notification_Change_volume" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetWPChangeTime:) name:@"Notification_Change_Time" object:nil];
    
    //监听休眠
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(receiveSleepNote:) name: NSWorkspaceWillSleepNotification object: NULL];
    //监听开机
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(receiveWakeNote:) name: NSWorkspaceDidWakeNotification object: NULL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    Reachability * reach = [Reachability reachabilityWithHostname:@"www.baidu.com"];
    //reach.reachableOnWWAN = NO;
    [reach startNotifier];
}

-(void)resetWPChangeTime:(NSNotification *)notification
{
    NSLog(@"重置时间:%@", [TBHelper getValueFromUserDefaults:@"wp_change_time"]);
    
    NSInteger changeTime;
    changeTime = [[TBHelper getValueFromUserDefaults:@"wp_change_time"] integerValue];
    
    [_changeTimer invalidate];
    _changeTimer = nil;
    _changeTimer = [NSTimer scheduledTimerWithTimeInterval:changeTime * 60 target:self selector:@selector(setWallpaperTimer) userInfo:nil repeats:YES];
    
}

-(void)updateImageFiles
{
    NSMutableDictionary *wpInfos = [[NSMutableDictionary alloc] init];
    NSString *jsonStr = [TBHelper getValueFromUserDefaults:@"wp_infos"];
    wpInfos = [[TBHelper jsonToDict:jsonStr] mutableCopy];
    
    [_imageFiles removeAllObjects];
    
    for(id key in wpInfos)
    {
        NSDictionary *info = [wpInfos objectForKey:key];
        dispatch_queue_t mySerialDispatchQueue = dispatch_queue_create("wp.tb.searchQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_async(mySerialDispatchQueue, ^{

            dispatch_async(dispatch_get_main_queue(), ^{
                [self searchFiles:[info objectForKey:@"path"] key:[info objectForKey:@"type"]];
            });
        });
    }
}

-(void)searchFiles:(NSString *)home key:(NSString *)key
{
    NSMutableArray *files = [NSMutableArray array];
    
    //文件管理器
    NSFileManager *manager = [NSFileManager defaultManager];
    //文件夹路径
    //NSString *home = rootPath;
    //NSString *home = [manager currentDirectoryPath];
    //枚举器
    NSDirectoryEnumerator *direnum = [manager enumeratorAtPath:home];
    
    //遍历文件夹内部所有jpg文档
    NSString *filename;
    BOOL isDir;
    while (filename = [direnum nextObject])
    {
        if ([[[filename pathExtension] lowercaseString] isEqualTo:@"jpg"] || [[[filename pathExtension] lowercaseString] isEqualTo:@"jpeg"] || [[[filename pathExtension] lowercaseString] isEqualTo:@"png"])
        {
            NSString *path = [NSString stringWithFormat:@"%@%@%@",home,@"/",filename];
            [manager fileExistsAtPath:path isDirectory:&isDir];
            if(isDir)
            {
                continue;
            }
            //NSLog(@"文件:%@", path);
            [files addObject:path];
        }
    }
    
    NSLog(@"添加壁纸:%@:%ld", key, [files count]);
    
    [_imageFiles setObject:[files copy] forKey:key];
    
    //int pos = arc4random() % [files count];
    //NSLog(@"随机图片:%@", [files objectAtIndex:pos]);
}

-(NSString *)getWallpaperByRandom
{
    if(!_imageFiles)
    {
        return nil;
    }
    
    NSString *importantStatus = [TBHelper getValueFromUserDefaults:@"important_status"];    //查看当前是否重要场合设置
    if([importantStatus isEqualToString:@"1"])
    {
        //是重要场合
        if([_imageFiles objectForKey:@"important"])
        {
            NSArray *files = [_imageFiles objectForKey:@"important"];
            if([files count] <= 0)
            {
                return nil;
            }
            
            int pos = arc4random() % [files count];
            NSString *file = [files objectAtIndex:pos];
            NSLog(@"得到随机图片:%@", file);
            return file;
        }
    }
    else
    {
        NSDictionary *wifi = [wifiInfo getWifiBSSID];
        if([_imageFiles objectForKey:[wifi objectForKey:@"bssid"]])
        {
            NSArray *files = [_imageFiles objectForKey:[wifi objectForKey:@"bssid"]];
            if([files count] <= 0)
            {
                return nil;
            }
            
            int pos = arc4random() % [files count];
            NSString *file = [files objectAtIndex:pos];
            NSLog(@"得到随机图片:%@", file);
            return file;
        }
        else
        {
            if([_imageFiles objectForKey:@"public"])
            {
                NSArray *files = [_imageFiles objectForKey:@"public"];
                if([files count] <= 0)
                {
                    return nil;
                }
                
                int pos = arc4random() % [files count];
                NSString *file = [files objectAtIndex:pos];
                NSLog(@"得到随机图片:%@", file);
                return file;
            }
        }
    }
    
    return nil;
}

-(void)setWallpaperTimer
{
    [self setWallpaper:nil];
}

-(void)setWallpaper:(NSNotification *)notification
{
    NSDictionary *info = [notification object];
    NSLog(@"设置壁纸Notifi:%@", info);
    
    NSScreen* thescreen;
    id theScreens = [NSScreen screens];
    for (thescreen in theScreens)
    {
        if(info)
        {
            //默认壁纸
            NSURL *wpURL = [[NSBundle mainBundle] URLForResource:@"default" withExtension:@"jpg"];
            NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:nil, NSWorkspaceDesktopImageFillColorKey, [NSNumber numberWithBool:NO], NSWorkspaceDesktopImageAllowClippingKey, [NSNumber numberWithInteger:NSImageScaleProportionallyUpOrDown], NSWorkspaceDesktopImageScalingKey, nil];
            [[NSWorkspace sharedWorkspace] setDesktopImageURL:wpURL forScreen:thescreen options:options error:nil];
        }
        else
        {
            dispatch_queue_t mySerialDispatchQueue = dispatch_queue_create("wp.tb.changewp", DISPATCH_QUEUE_SERIAL);
            dispatch_async(mySerialDispatchQueue, ^{

                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *wpFile = [self fixWallPapge:[self getWallpaperByRandom]];
                    //NSString *wpFile = @"/Users/wu/Desktop/8277070715932695688e8.jpg";
                    NSLog(@"更换壁纸:%@", wpFile);
                    if(wpFile)
                    {
                        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:nil, NSWorkspaceDesktopImageFillColorKey, [NSNumber numberWithBool:NO], NSWorkspaceDesktopImageAllowClippingKey, [NSNumber numberWithInteger:NSImageScaleProportionallyUpOrDown], NSWorkspaceDesktopImageScalingKey, nil];
                        [[NSWorkspace sharedWorkspace] setDesktopImageURL:[NSURL fileURLWithPath:wpFile] forScreen:thescreen options:options error:nil];
                        
                        //NSError *error = nil;
                        //[[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:wpFile] error:&error];
                    }
                });
            });
        }
    }
}

-(void)setVolume:(NSNotification *)notification
{
    AudioObjectPropertyAddress addr;
    addr.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
    addr.mScope = kAudioObjectPropertyScopeGlobal;
    addr.mElement = kAudioObjectPropertyElementMaster;

    //得到默认音频输出设备
    AudioDeviceID outputDeviceID;
    UInt32 size = sizeof(AudioDeviceID);
    OSStatus err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &addr, 0, NULL, &size, &outputDeviceID);

    if (err == noErr)
    {
        AudioObjectPropertyAddress addr;
        addr.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume;
        addr.mScope = kAudioObjectPropertyScopeOutput;
        addr.mElement = kAudioObjectPropertyElementMaster;
        Float32 volume;

        //得到当前音量
        AudioObjectGetPropertyData(outputDeviceID, &addr, 0, NULL, &size, &volume);
        NSLog(@"volume: %lf", volume);

        //设置音量
        size = sizeof(Float32);
        
        NSDictionary *info = [notification object];
        if([info[@"type"] isEqualToString:@"small"])
        {
            volume = 0.1;
        }
        else if([info[@"type"] isEqualToString:@"middle"])
        {
            volume = 0.5;
        }
        else if([info[@"type"] isEqualToString:@"big"])
        {
            volume = 0.8;
        }
        else
        {
            volume = 0.1;
        }
        
        AudioObjectSetPropertyData(outputDeviceID, &addr, 0, NULL, size, &volume);
    }
}


-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability * reach = [note object];
    
    if([reach isReachable])
    {
        //_notificationLabel.stringValue = @"Notification Says Reachable";
        NSLog(@"网络已连接");
    }
    else
    {
        //_notificationLabel.stringValue = @"Notification Says Unreachable";
        NSLog(@"网络已断开");
    }
    
    //针对场合进行声音设置
    NSString *importantStatus = [TBHelper getValueFromUserDefaults:@"important_status"];    //查看当前是否重要场合设置
    if([importantStatus isEqualToString:@"1"])
    {
        //是重要场合
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Change_volume" object:@{@"type":@"small"} userInfo:nil];
    }
    else
    {
        NSDictionary *wifi = [wifiInfo getWifiBSSID];
        if([_imageFiles objectForKey:[wifi objectForKey:@"bssid"]])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Change_volume" object:@{@"type":@"middle"} userInfo:nil];
        }
        else
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Change_volume" object:@{@"type":@"small"} userInfo:nil];
        }
    }
    
    
    //切换网络时,先换成默认
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Change_Wallpaper" object:@{@"status":@"default"} userInfo:nil];   //切换网络时
    
    //按环境设置壁纸
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Change_Wallpaper" object:nil userInfo:nil];   //切换网络时
    //[self setWallpaper:nil];    //每次网络切换就更换壁纸
    
    NSLog(@"wifi:%@", [wifiInfo getWifiBSSID]);
}

-(NSString *)fixWallPapge:(NSString *)imageFile
{
    if(!imageFile)
    {
        return nil;
    }
    
    
    //NSString *imageFile = @"/Users/wu/Desktop/8277070715932695688e8.jpg";
    NSImage *bgImage = [[NSImage alloc] initWithContentsOfFile:imageFile];
    
    //if oriImgHeight * 0.8 < float(oriImgWidth) * 9 / 16 < oriImgHeight * 1.5 and min(oriImg.size) > min(bgImgWidth, bgImgHeight) * 0.8:
    
    if([bgImage isScaleBy16_9])
    {
        return [self writeFile:bgImage];
    }
    
    NSImage *ovImage = [bgImage copy];
    
    
    NSImage *blurImage = [bgImage blur:20];
    NSImage *resizeImage = [blurImage resize:CGSizeMake(1440, 900) bigScaleStatus:YES];
    NSImage *wpImage = [resizeImage sliceImage:NSMakeRect(0, 0, 1440, 900)];
    
    NSImage *roundImage = [[ovImage resize:CGSizeMake(1440*0.85, 900*0.85) bigScaleStatus:NO] roundImage:30];
    NSImage *objImage = [wpImage merge:roundImage];
    return [self writeFile:objImage];
}

-(NSString *)writeFile:(NSImage *)image
{
    NSString *wpFile = [NSString stringWithFormat:@"/tmp/%@.jpg", [TBHelper UDID]];
    CGImageRef cgRef = [image CGImageForProposedRect:NULL
                                                context:nil
                                                  hints:nil];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:[image size]];
    NSData *pngData = [newRep representationUsingType:NSBitmapImageFileTypeJPEG2000 properties:nil];
    [pngData writeToFile:wpFile atomically:YES];
    //sleep(2);
    return wpFile;
}
@end
