//
//  WPSettingView.m
//  TBWallpaper
//
//  Created by 吴韵卫 on 2021/1/22.
//

#import "WPSettingView.h"
#import "NSImage+Blur.h"
#import "WPSetPathView.h"
#import "TBHelper.h"
#import "wifiInfo.h"
#import "WPChangeHistoryView.h"

@interface WPSettingView ()<NSTableViewDelegate,NSTableViewDataSource, NSTextFieldDelegate>

@property (strong) NSMutableDictionary *wpInfos;
@property (strong) NSMutableArray *wpList;
@property (strong) NSMenu *tableMenu;

@end

@implementation WPSettingView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    _wpInfos = [[NSMutableDictionary alloc] init];
    _wpList = [[NSMutableArray alloc] init];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.usesAlternatingRowBackgroundColors = YES;    //背景颜色交替
    
    _tableMenu = [[NSMenu alloc] init];
    _tableMenu.autoenablesItems = false;
    NSMenuItem *delItem = [[NSMenuItem alloc] initWithTitle:@"添加" action:@selector(addRow:) keyEquivalent:@""];
    NSMenuItem *addItem = [[NSMenuItem alloc] initWithTitle:@"删除" action:@selector(delRow:) keyEquivalent:@""];
    //NSMenuItem *updateItem = [[NSMenuItem alloc] initWithTitle:@"重载所有图片" action:@selector(updateImage:) keyEquivalent:@""];
    //[_tableMenu addItem:updateItem];
    [_tableMenu addItem:delItem];
    [_tableMenu addItem:addItem];
    
    _tableView.menu = _tableMenu;
    
    NSString *wpChangeTime = [TBHelper getValueFromUserDefaults:@"wp_change_time"];
    if(wpChangeTime)
    {
        [_changeTime setStringValue:wpChangeTime];
    }
    
    _changeTime.delegate = self;
    NSNumberFormatter *numberFormater = [[NSNumberFormatter alloc] init];
    [numberFormater setNumberStyle:kCFNumberFormatterNoStyle];
    [_changeTime setFormatter:numberFormater];
    
    NSClickGestureRecognizer *click = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(showChangeHistoryView:)];
    [_lastWPPath addGestureRecognizer:click];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLastWallpaperPath) name:@"Notification_Update_Last_path" object:nil];
}

-(void)viewWillAppear {
    NSString *jsonStr = [TBHelper getValueFromUserDefaults:@"wp_infos"];
    _wpInfos = [[TBHelper jsonToDict:jsonStr] mutableCopy];
    //NSLog(@"已存信息:%@", _wpList);
    
    if(_wpInfos)
    {
        NSString *importantStatus = [TBHelper getValueFromUserDefaults:@"important_status"];    //查看当前是否重要场合设置
        if([importantStatus isEqualToString:@"1"])
        {
            [_currentEnv setStringValue: [[_wpInfos objectForKey:@"important"] objectForKey:@"title"]];
        }
        else
        {
            NSDictionary *wifi = [wifiInfo getWifiBSSID];
            if([_wpInfos objectForKey:[wifi objectForKey:@"bssid"]])
            {
                [_currentEnv setStringValue: [[_wpInfos objectForKey:[wifi objectForKey:@"bssid"]] objectForKey:@"title"]];
            }
            else
            {
                [_currentEnv setStringValue: [[_wpInfos objectForKey:@"public"] objectForKey:@"title"]];
            }
        }
        
        [_wpList removeAllObjects];
        for(id key in _wpInfos)
        {
            NSDictionary *info = [_wpInfos objectForKey:key];
            [_wpList addObject:info];
        }
    }
    
    [self updateLastWallpaperPath];
    
    [_tableView reloadData];
}

-(void)updateLastWallpaperPath
{
    [_lastWPPath setStringValue:[TBHelper getValueFromUserDefaults:@"last_wp_path"]];
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    NSLog(@"controlTextDidChange: stringValue == %@", [textField stringValue]);
    
    [TBHelper setValueFromUserDefaults:@"wp_change_time" value:[textField stringValue]];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_wpList count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSDictionary *info = [_wpList objectAtIndex:row];
    if(!info)
    {
        return nil;
    }
    
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    if ([tableColumn.identifier isEqualToString:@"title"])
    {
        cellView.textField.stringValue = [info objectForKey:@"title"];
    }
    else if ([tableColumn.identifier isEqualToString:@"env"])
    {
        if([[info objectForKey:@"type"] isEqualToString:@"public"])
        {
            cellView.textField.stringValue = @"不指定WIFI";
        }
        else if([[info objectForKey:@"type"] isEqualToString:@"important"])
        {
            cellView.textField.stringValue = @"重要场合";
        }
        else
        {
            cellView.textField.stringValue = @"指定WIFI";
        }
    }
    else if ([tableColumn.identifier isEqualToString:@"wifi"])
    {
        cellView.textField.stringValue = [info objectForKey:@"wifi"];
    }
    else if ([tableColumn.identifier isEqualToString:@"path"])
    {
        cellView.textField.stringValue = [info objectForKey:@"path"];
    }
    
    return cellView;
}

-(void)addRow:(id)sender {
    WPSetPathView *view = [[WPSetPathView alloc] init];
    [self presentViewControllerAsModalWindow:view];
}

-(void)delRow:(id)sender {
    NSLog(@"删除行:%ld", (long)_tableView.selectedRow);
    
    if(_tableView.selectedRow != -1)
    {
        NSDictionary *info = [_wpList objectAtIndex:_tableView.selectedRow];
        [_wpInfos removeObjectForKey:[info objectForKey:@"type"]];
        
        [_wpList removeObjectAtIndex:_tableView.selectedRow];
        [_tableView reloadData];
        
        if([_wpList count] > 0)
        {
            NSString *newJsonStr = [TBHelper dictToJson:[_wpInfos copy]];
            [TBHelper setValueFromUserDefaults:@"wp_infos" value:newJsonStr];
        }
        else
        {
            [TBHelper delValueFromUserDefaults:@"wp_infos"];
        }
    }
}

-(void)updateImage:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Update_Images" object:nil userInfo:nil];
}

- (IBAction)changeWP:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Change_Wallpaper" object:nil userInfo:nil];
}

- (IBAction)QuitAPP:(id)sender {
    [[NSApplication sharedApplication] terminate:self];
}

- (IBAction)resetChangeTime:(id)sender {
    if([_changeTime stringValue])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Notification_Change_Time" object:nil userInfo:nil];
    }
}
- (void)showChangeHistoryView:(id)sender {
    WPChangeHistoryView *view = [[WPChangeHistoryView alloc] init];
    [self presentViewControllerAsModalWindow:view];
}

@end
