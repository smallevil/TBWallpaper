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
#import "NSScreen+DisplayInfo.h"


@interface AppDelegate ()

@property (nonatomic,strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSPopover *popover;

@property (nonatomic, strong) NSMutableDictionary *imageFiles;

@property (nonatomic, assign) NSTimer *changeTimer;

@property (nonatomic, strong) NSTask *caffeinateTask;

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
                    [self enableSleep];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_DND_OFF" object:nil userInfo:nil];
                    [TBHelper setValueFromUserDefaults:@"important_status" value:@"0"];
                }
                else
                {
                    [self disableSleep];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_DND_ON" object:nil userInfo:nil];
                    [TBHelper setValueFromUserDefaults:@"important_status" value:@"1"];
                }
            }
            else
            {
                [self disableSleep];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_DND_ON" object:nil userInfo:nil];
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
    //statusItem.button.title = @"xxxx";
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
    
    //关机(休眠)时直接设成最小声音(此处好像无效)
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Change_volume" object:@{@"type":@"small"} userInfo:nil];
    NSLog(@"receiveSleepNote: %@", [note name]);
}
 
- (void) receiveWakeNote: (NSNotification*) note
{
    //此函数会被多次触发
    
    NSLog(@"receiveWakeNote: %@", [note name]);
    
    //关机(休眠)时直接设成最小声音
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Change_volume" object:@{@"type":@"small"} userInfo:nil];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(turnDoNotDisturbOn) name:@"Notification_DND_ON" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(turnDoNotDisturbOff) name:@"Notification_DND_OFF" object:nil];
    
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
                [self searchFiles:info];
            });
        });
    }
}

-(void)searchFiles:(NSDictionary *)info
{
    NSMutableArray *files = [NSMutableArray array];
    
    //文件管理器
    NSFileManager *manager = [NSFileManager defaultManager];
    //文件夹路径
    NSString *home = [info objectForKey:@"path"];
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
    
    [info setValue:[files copy] forKey:@"files"];
    NSLog(@"添加壁纸:%@:%ld", [info objectForKey:@"type"], [files count]);
    
    [_imageFiles setObject:info forKey:[info objectForKey:@"type"]];
    
    //int pos = arc4random() % [files count];
    //NSLog(@"随机图片:%@", [files objectAtIndex:pos]);
}

-(NSString *)getWallpaperByRandom:(NSScreen *)thescreen
{
    if(!_imageFiles)
    {
        return nil;
    }
    
    NSString *file = @"";
    NSString *importantStatus = [TBHelper getValueFromUserDefaults:@"important_status"];    //查看当前是否重要场合设置
    if([importantStatus isEqualToString:@"1"])
    {
        //是重要场合
        if([_imageFiles objectForKey:@"important"])
        {
            NSArray *files = [[_imageFiles objectForKey:@"important"] objectForKey:@"files"];
            if([files count] <= 0)
            {
                return nil;
            }
            
            [TBHelper setValueFromUserDefaults:@"last_wp_env_title" value:[[_imageFiles objectForKey:@"important"] objectForKey:@"title"]];
            
            int pos = arc4random() % [files count];
            file = [files objectAtIndex:pos];
            NSLog(@"得到随机图片:%@", file);
        }
    }
    else
    {
        NSDictionary *wifi = [wifiInfo getWifiBSSID];
        if([_imageFiles objectForKey:[wifi objectForKey:@"bssid"]])
        {
            NSArray *files = [[_imageFiles objectForKey:[wifi objectForKey:@"bssid"]] objectForKey:@"files"];
            if([files count] <= 0)
            {
                return nil;
            }
            
            [TBHelper setValueFromUserDefaults:@"last_wp_env_title" value:[[_imageFiles objectForKey:[wifi objectForKey:@"bssid"]] objectForKey:@"title"]];
            
            int pos = arc4random() % [files count];
            file = [files objectAtIndex:pos];
            NSLog(@"得到随机图片:%@", file);
        }
        else
        {
            if([_imageFiles objectForKey:@"public"])
            {
                NSArray *files = [[_imageFiles objectForKey:@"public"] objectForKey:@"files"];
                if([files count] <= 0)
                {
                    return nil;
                }
                
                [TBHelper setValueFromUserDefaults:@"last_wp_env_title" value:[[_imageFiles objectForKey:@"public"] objectForKey:@"title"]];
                
                int pos = arc4random() % [files count];
                file = [files objectAtIndex:pos];
                NSLog(@"得到随机图片:%@", file);
            }
        }
    }
    
    if(file.length <= 0)
    {
        return nil;
    }
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:file])
    {
        //随机得到的文件并不存在,应该是手动删除了.需要重新扫描所有目录
        NSLog(@"文件丢失,重新扫描");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Update_Images" object:nil userInfo:nil];
        return nil;
    }
    
    [TBHelper setValueFromUserDefaults:@"last_wp_path" value:file];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Update_Last_path" object:nil userInfo:nil];
    
    NSDate *date = [NSDate date];
    NSTimeInterval sec = [date timeIntervalSinceNow];
    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
    NSDateFormatter * df = [[NSDateFormatter alloc] init ];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *changeTime = [df stringFromDate:currentDate];
    
    NSString *wpLastPath = file;
    NSString *screenName = thescreen.localizedName;
    NSString *envTitle = [TBHelper getValueFromUserDefaults:@"last_wp_env_title"];
    //self.statusItem.button.toolTip = envTitle;
    NSDictionary *lastInfo = [NSDictionary dictionaryWithObjectsAndKeys:screenName, @"screen", changeTime, @"time", envTitle, @"title", wpLastPath, @"path", nil];
    
    NSString *historyFile = [NSString stringWithFormat:@"%@/history.plist", NSTemporaryDirectory()];
    NSMutableArray *history = [NSMutableArray arrayWithContentsOfFile:historyFile];
    if(!history)
    {
        history = [[NSMutableArray alloc] init];
        [history addObject:lastInfo];
    }
    else
    {
        [history insertObject:lastInfo atIndex:0];
    }
    NSLog(@"记录文件:%@", historyFile);
    //NSLog(@"历史记录:%@", history);
    
    NSMutableArray *newHistory = [[NSMutableArray alloc] init];
    if([history count] > 100)
    {
        newHistory = [[history subarrayWithRange:NSMakeRange(0, 99)] mutableCopy];
    }
    else
    {
        newHistory = history;
    }
    [newHistory writeToFile:historyFile atomically:YES];
    
    return file;
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
        //NSLog(@"屏幕对像:%@--%@--%@", thescreen.localizedName, [thescreen displayID], [thescreen displayName]);
        if(info)
        {
            [TBHelper setValueFromUserDefaults:@"last_wp_path" value:@"默认壁纸"];
            
            //默认壁纸
            NSURL *wpURL = [[NSBundle mainBundle] URLForResource:@"default" withExtension:@"jpg"];
            NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:nil, NSWorkspaceDesktopImageFillColorKey, [NSNumber numberWithBool:NO], NSWorkspaceDesktopImageAllowClippingKey, [NSNumber numberWithInteger:NSImageScaleProportionallyUpOrDown], NSWorkspaceDesktopImageScalingKey, nil];
            [[NSWorkspace sharedWorkspace] setDesktopImageURL:wpURL forScreen:thescreen options:options error:nil];
        }
        else
        {
            NSString *tmpPath = NSTemporaryDirectory();
            NSURL *lastImageURL = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen:thescreen];
            NSString *lastImagePath = [lastImageURL path];
            NSLog(@"xxxx目录:%@", tmpPath);
            NSLog(@"xxxx文件:%@", lastImagePath);
            
            NSRange range = [lastImagePath rangeOfString:tmpPath];
            if(range.location != NSNotFound)
            {
                //非默认图
                if([[NSFileManager defaultManager] fileExistsAtPath:lastImagePath])
                {
                    NSLog(@"非默认图,可以删除:%@", lastImagePath);
                    NSError *error = nil;
                    [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:lastImagePath] error:&error];
                }
            }
            
            dispatch_queue_t mySerialDispatchQueue = dispatch_queue_create("wp.tb.changewp", DISPATCH_QUEUE_SERIAL);
            dispatch_async(mySerialDispatchQueue, ^{

                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *wpFile = [self fixWallPapge:[self getWallpaperByRandom:thescreen]];
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
    
    if(imageFile.length <= 0)
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
    NSString *wpFile = [NSString stringWithFormat:@"%@/tbwp.%@.jpg", NSTemporaryDirectory(), [TBHelper UDID]];
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

//////////////////////////////////////////////    勿扰模式   ////////////////////////////////////////
-(void)turnDoNotDisturbOn
{
    // The trick is to set DND time range from 00:00 (0 minutes) to 23:59 (1439 minutes),
    // so it will always be on
    CFPreferencesSetValue(CFSTR("dndStart"), (__bridge CFPropertyListRef)(@(0.0f)),
                          CFSTR("com.apple.notificationcenterui"),
                          kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);

    CFPreferencesSetValue(CFSTR("dndEnd"), (__bridge CFPropertyListRef)(@(1440.f)),
                          CFSTR("com.apple.notificationcenterui"),
                          kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);

    CFPreferencesSetValue(CFSTR("doNotDisturb"), (__bridge CFPropertyListRef)(@(YES)),
                          CFSTR("com.apple.notificationcenterui"),
                          kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);

    // Notify all the related daemons that we have changed Do Not Disturb preferences
    commitDoNotDisturbChanges();
}


-(void) turnDoNotDisturbOff
{
    CFPreferencesSetValue(CFSTR("dndStart"), NULL,
                        CFSTR("com.apple.notificationcenterui"),
                        kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);

    CFPreferencesSetValue(CFSTR("dndEnd"), NULL,
                          CFSTR("com.apple.notificationcenterui"),
                          kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);

    CFPreferencesSetValue(CFSTR("doNotDisturb"), (__bridge CFPropertyListRef)(@(NO)),
                          CFSTR("com.apple.notificationcenterui"),
                          kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);

    commitDoNotDisturbChanges();
}

void commitDoNotDisturbChanges(void)
{
    /// XXX: I'm using kCFPreferencesCurrentUser placeholder here which means that this code must
    /// be run under regular user's account (not root/admin). If you're going to run this code
    /// from a privileged helper, use kCFPreferencesAnyUser in order to toggle DND for all users
    /// or drop privileges and use kCFPreferencesCurrentUser.
    CFPreferencesSynchronize(CFSTR("com.apple.notificationcenterui"), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName: @"com.apple.notificationcenterui.dndprefs_changed"
                                                               object: nil userInfo: nil
                                                   deliverImmediately: YES];
}

//阻止电脑进入休眠
-(void)disableSleep
{
    //命令
    //caffeinate -d -i -s -u
    
    if(_caffeinateTask)
    {
        [self enableSleep];
    }
    
    _caffeinateTask = [[NSTask alloc] init];
    [_caffeinateTask setLaunchPath:@"/usr/bin/caffeinate"];
    [_caffeinateTask setArguments:@[@"-d", @"-i", @"-s", @"-t 86400"]];    //一天,即使出意外,一天后也能自动恢复
    [_caffeinateTask launch];
}

-(void)enableSleep
{
    if(_caffeinateTask)
    {
        [_caffeinateTask terminate];
        _caffeinateTask = nil;
    }
    else
    {
        _caffeinateTask = nil;
        
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/bin/killall"];
        [task setArguments:@[@"caffeinate"]];    //杀死进程
        [task launch];
    }
}

@end
