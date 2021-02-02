//
//  WPSetPathView.m
//  TBWallpaper
//
//  Created by 吴韵卫 on 2021/1/31.
//

#import "WPSetPathView.h"
#import "wifiInfo.h"
#import "TBHelper.h"

@interface WPSetPathView ()

@property (nonatomic, strong) NSDictionary *wifi;
@property (nonatomic, strong) NSArray *intros;
@end

@implementation WPSetPathView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    self.title = @"添加新环境";
    
    [_envType setTarget:self];
    [_envType setAction:@selector(handlePopBtn:)];
    
    _intros = [NSArray arrayWithObjects:@"此项可同时存在多个.当连接到指定WIFI时,随机设置壁纸.", @"此选项只能存在一个.当连接到非指定WIFI时(包括未连接网络时),随机设置壁纸.", @"此选项只能存在一个,且只能手动控制切换.当有重要场合时,可以使用Command+鼠标左键3连击进行切换,随机设置壁纸.", nil];
    
    [_envIntro setStringValue:[_intros objectAtIndex:0]];
    
    _wifi = [wifiInfo getWifiBSSID];
    
    [_envTitle setStringValue:_wifi[@"ssid"]];
    [_wifiBSSID setStringValue:_wifi[@"bssid"]];
}

- (void)handlePopBtn:(NSPopUpButton *)popBtn {

    NSString *title = popBtn.selectedItem.title;
    NSLog(@"%ld:%@", (long)popBtn.indexOfSelectedItem, title);
    
    [_envIntro setStringValue:[_intros objectAtIndex:popBtn.indexOfSelectedItem]];
    
    if(popBtn.indexOfSelectedItem == 0)
    {
        //指定wifi
        _wifiBSSID.enabled = YES;
        [_wifiBSSID setStringValue:_wifi[@"bssid"]];
    }
    else if(popBtn.indexOfSelectedItem == 1)
    {
        //不指定wifi
        //_wifiBSSID.enabled = NO;
        _wifiBSSID.editable = NO;
        [_wifiBSSID setStringValue:@""];
    }
    else if(popBtn.indexOfSelectedItem == 2)
    {
        //重要场合
        //_wifiBSSID.enabled = NO;
        _wifiBSSID.editable = NO;
        [_wifiBSSID setStringValue:@""];
    }
}


- (IBAction)openPath:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setPrompt:@"选择"];     // 设置默认选中按钮的显示（OK 、打开，Open ...）
    [panel setMessage: @"选择图片目录"];    // 设置面板上的提示信息
    [panel setCanChooseDirectories : YES]; // 是否可以选择文件夹
    [panel setCanCreateDirectories : NO]; // 是否可以创建文件夹
    [panel setCanChooseFiles : NO];      // 是否可以选择文件
    [panel setAllowsMultipleSelection : NO]; // 是否可以多选
    //[panel setAllowedFileTypes : [NSArray arrayWithObjects:@"png",@"jpg",@"bmp", nil]];        // 所能打开文件的后
    [panel setDirectoryURL:[NSURL URLWithString:@"~/Pictures"]];                    // 打开的文件路径
    
    NSInteger result = [panel runModal];
    if (result == NSModalResponseOK)
    {
        [_imagePath setStringValue:[[[panel URLs] objectAtIndex:0] path]];
    }
   
}
- (IBAction)addImagePath:(id)sender {
    
    NSString *type;
    if(_envType.indexOfSelectedItem == 1)
    {
        type = @"public";
    }
    else if(_envType.indexOfSelectedItem == 2)
    {
        type = @"important";
    }
    else
    {
        type = [_wifiBSSID stringValue];
    }
    
    if([[_imagePath stringValue] length] <= 0)
    {
        //没有目录
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"需要选择一个图片目录"];
        [alert setInformativeText:@"程序会在达到更换壁纸时间时,随机从目录中选择一张图片并设置为当前壁纸."];
        //[alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"确定"];
        [alert runModal];
        
        return;
    }
    
    if([[_envTitle stringValue] length] <= 0)
    {
        //没有填写名字(说明)
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"设置一个名字"];
        [alert setInformativeText:@"说明此目录图片什么情况使用,方便以后管理."];
        //[alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"确定"];
        [alert runModal];
        
        return;
    }
    
    if(_envType.indexOfSelectedItem == 0 && [[_wifiBSSID stringValue] length] <= 0)
    {
        //指定wifi时没有填写wifi bssid
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"设置WIFI BSSID"];
        [alert setInformativeText:@"当指定WIFI时,必须填写BSSID,默认为当前连接的WIFI.当连接此WIFI时,程序从指定目录选择图片进行设置."];
        //[alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"确定"];
        [alert runModal];
        
        return;
    }
    
    NSString *jsonStr = [TBHelper getValueFromUserDefaults:@"wp_infos"];
    NSMutableDictionary *wpInfos = [[NSMutableDictionary alloc] init];
    if(jsonStr)
    {
        wpInfos = [[TBHelper jsonToDict:jsonStr] mutableCopy];
        
        if([wpInfos objectForKey:type])
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"出错"];
            [alert setInformativeText:@"已经添加此环境,如需更新请删除后重新添加."];
            //[alert addButtonWithTitle:@"Cancel"];
            [alert addButtonWithTitle:@"确定"];
            [alert runModal];
            
            return;
        }
    }
    
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", [_envTitle stringValue], @"title", [_wifiBSSID stringValue], @"wifi", [_imagePath stringValue], @"path",  nil];
    
    [wpInfos setObject:info forKey:type];
    NSLog(@"全部设置信息:%@", wpInfos);
    NSString *newJsonStr = [TBHelper dictToJson:[wpInfos copy]];
    [TBHelper setValueFromUserDefaults:@"wp_infos" value:newJsonStr];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Update_Images" object:nil userInfo:nil];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"已添加"];
    [alert setInformativeText:@"已添加环境,其下所有图片正在加入图库."];
    //[alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"确定"];
    [alert runModal];
}
@end
