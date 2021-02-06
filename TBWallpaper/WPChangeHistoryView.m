//
//  WPChangeHistoryView.m
//  TBWallpaper
//
//  Created by 吴韵卫 on 2021/2/4.
//

#import "WPChangeHistoryView.h"

@interface WPChangeHistoryView ()<NSTableViewDelegate,NSTableViewDataSource>

@property (nonatomic, strong) NSMutableArray *history;
@property (strong) NSMenu *tableMenu;

@end

@implementation WPChangeHistoryView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    self.title = @"历史记录";
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.usesAlternatingRowBackgroundColors = YES;    //背景颜色交替
    
    _tableMenu = [[NSMenu alloc] init];
    _tableMenu.autoenablesItems = false;
    NSMenuItem *refreshItem = [[NSMenuItem alloc] initWithTitle:@"刷新" action:@selector(refreshTable:) keyEquivalent:@""];
    NSMenuItem *copyItem = [[NSMenuItem alloc] initWithTitle:@"复制" action:@selector(copyPath:) keyEquivalent:@""];
    NSMenuItem *openItem = [[NSMenuItem alloc] initWithTitle:@"打开" action:@selector(openWPFile:) keyEquivalent:@""];
    [_tableMenu addItem:refreshItem];
    [_tableMenu addItem:copyItem];
    [_tableMenu addItem:openItem];
    _tableView.menu = _tableMenu;
    
}

-(void)viewWillAppear {
    [self refreshTable:nil];
}

-(void)refreshTable:(id)sender
{
    if(!_history)
    {
        _history = [[NSMutableArray alloc] init];
    }
    else
    {
        [_history removeAllObjects];
    }
    
    NSString *historyFile = [NSString stringWithFormat:@"%@/history.plist", NSTemporaryDirectory()];
    _history = [NSMutableArray arrayWithContentsOfFile:historyFile];
    //NSLog(@"已存记录:%@", _history);
    [_tableView reloadData];
}

-(void)copyPath:(id)sender
{
    NSLog(@"复制行:%ld", (long)_tableView.selectedRow);
    
    if(_tableView.selectedRow != -1)
    {
        NSDictionary *info = [_history objectAtIndex:_tableView.selectedRow];
        NSString *imagePath = [info objectForKey:@"path"];
        
        [[NSPasteboard generalPasteboard] clearContents];
        [[NSPasteboard generalPasteboard] setString:imagePath forType:NSPasteboardTypeString];
    }
}

-(void)openWPFile:(id)sender
{
    NSLog(@"选中行:%ld", (long)_tableView.selectedRow);
    
    if(_tableView.selectedRow != -1)
    {
        NSDictionary *info = [_history objectAtIndex:_tableView.selectedRow];
        NSString *imagePath = [info objectForKey:@"path"];
        
        NSURL *fileURL = [NSURL fileURLWithPath:imagePath];
        //NSURL *folderURL = [fileURL URLByDeletingLastPathComponent];
        //[[NSWorkspace sharedWorkspace] openURL: folderURL];
        [[NSWorkspace sharedWorkspace] selectFile:[fileURL path] inFileViewerRootedAtPath:nil];
    }
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_history count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSDictionary *info = [_history objectAtIndex:row];
    if(!info)
    {
        return nil;
    }
    
    //NSLog(@"行信息:%@", info);
    
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    if ([tableColumn.identifier isEqualToString:@"screen"])
    {
        cellView.textField.stringValue = [info objectForKey:@"screen"];
    }
    else if ([tableColumn.identifier isEqualToString:@"env"])
    {
        cellView.textField.stringValue = [info objectForKey:@"title"];
    }
    else if ([tableColumn.identifier isEqualToString:@"time"])
    {
        cellView.textField.stringValue = [info objectForKey:@"time"];
    }
    else if ([tableColumn.identifier isEqualToString:@"path"])
    {
        cellView.textField.stringValue = [info objectForKey:@"path"];
    }
    
    return cellView;
}

@end
