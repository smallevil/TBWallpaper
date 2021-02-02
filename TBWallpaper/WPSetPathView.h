//
//  WPSetPathView.h
//  TBWallpaper
//
//  Created by 吴韵卫 on 2021/1/31.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface WPSetPathView : NSViewController

@property (strong) IBOutlet NSPopUpButton *envType;
@property (strong) IBOutlet NSTextField *envTitle;
@property (strong) IBOutlet NSTextField *wifiBSSID;
- (IBAction)openPath:(id)sender;
@property (strong) IBOutlet NSTextField *imagePath;
- (IBAction)addImagePath:(id)sender;
@property (strong) IBOutlet NSTextField *envIntro;

@end

NS_ASSUME_NONNULL_END
