//
//  WPSettingView.h
//  TBWallpaper
//
//  Created by 吴韵卫 on 2021/1/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface WPSettingView : NSViewController
- (IBAction)QuitAPP:(id)sender;
- (IBAction)changeWP:(id)sender;
@property (strong) IBOutlet NSTextField *changeTime;
@property (strong) IBOutlet NSScrollView *envTable;
@property (strong) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSTextField *currentEnv;
- (IBAction)resetChangeTime:(id)sender;
@property (strong) IBOutlet NSTextField *lastWPPath;
- (void)showChangeHistoryView:(id)sender;

@end

NS_ASSUME_NONNULL_END
