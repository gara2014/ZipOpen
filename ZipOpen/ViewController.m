//
//  ViewController.m
//  ZipOpen
//
//  Created by gara on 2017/9/12.
//  Copyright © 2017年 gara. All rights reserved.
//

#import "ViewController.h"
#import "WebViewController.h"
#import "ZipArchive.h"
#import "NSString+URL.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSString *dstPath;
@property (nonatomic, strong) NSString *srcPath;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"根目录" style:UIBarButtonItemStylePlain target:self action:@selector(rootAction:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"后退" style:UIBarButtonItemStylePlain target:self action:@selector(backAction:)];
    self.dataSource = [[NSMutableArray alloc] init];
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/localFile"];
    NSArray *array = [self getAllDirAndFile:path];
    [self.dataSource addObject:array];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(urlReceived:) name:@"urlReceived" object:nil];
}

- (IBAction)backAction:(id)sender {
    if (self.dataSource.count == 2) {
        [self.dataSource removeAllObjects];
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/localFile"];
        NSArray *array = [self getAllDirAndFile:path];
        [self.dataSource addObject:array];
        [self.tableView reloadData];
    } else if (self.dataSource.count > 1) {
        [self.dataSource removeLastObject];
        [self.tableView reloadData];
    }
}

- (IBAction)rootAction:(id)sender {
    [self.dataSource removeAllObjects];
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/localFile"];
    NSArray *array = [self getAllDirAndFile:path];
    [self.dataSource addObject:array];
    [self.tableView reloadData];
}

- (void)urlReceived:(NSNotification *)aNotification {
    NSURL *url = aNotification.object;
    NSString *srcPath = [url absoluteString];
    srcPath = [srcPath URLDecodedString];
    if([srcPath rangeOfString:@"file://"].location != NSNotFound) {
        srcPath = [srcPath substringFromIndex:7];
    }
    
    NSString *fileNameStr = [srcPath lastPathComponent];
    NSString *dstPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/localFile"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:dstPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dstPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    dstPath = [dstPath stringByAppendingPathComponent:fileNameStr];
    NSString *ext = [dstPath pathExtension];
    if([ext isEqualToString:@"zip"]) {
        BOOL success = [self unzipFile:srcPath dstPath:dstPath password:nil];
        if (!success) {
            self.srcPath = srcPath;
            self.dstPath = dstPath;
            [self showPwdAlertView];
        }
    } else {
        NSData *data = [NSData dataWithContentsOfURL:url];
        NSError *error = nil;
        [data writeToFile:dstPath options:NSDataWritingAtomic error:&error];
        NSLog(@"success:%@", error);
        
        [self contentsOfDirectionChanged];
    }
}

- (BOOL)unzipFile:(NSString*)srcPath dstPath:(NSString*)dstPath password:(NSString*)password {
    NSString *path = srcPath;
    if (path.length > 0) {
        ZipArchive* zip = [[ZipArchive alloc] init];
        zip.stringEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        BOOL suc = [zip UnzipOpenFile:path Password:password];
        if (suc) {
            NSString *outputDir = [dstPath stringByDeletingPathExtension];
            if (outputDir.length > 0) {
                NSString *outputDirTemp = [outputDir stringByAppendingString:@"_temp"];
                if([zip UnzipFileTo:outputDirTemp overWrite:YES]) {
                    
                    if ([[NSFileManager defaultManager] fileExistsAtPath:outputDir]) {
                        [[NSFileManager defaultManager] removeItemAtPath:outputDir error:nil];
                    }
                    suc = [[NSFileManager defaultManager] moveItemAtPath:outputDirTemp toPath:outputDir error:nil];
                    
                    [self contentsOfDirectionChanged];
                }
                else {
                    //打开失败，删掉缓存文件
                    [[NSFileManager defaultManager] removeItemAtPath:outputDirTemp error:nil];
                    return NO;
                }
            }
        }
        else {
            return NO;
        }
    }
    
    return YES;
}

- (void)showPwdAlertView {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"请输入口令" message:@"" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定",nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UITextField *txt = [alertView textFieldAtIndex:0];
    [self unzipFile:self.srcPath dstPath:self.dstPath password:txt.text];
}

- (void)contentsOfDirectionChanged {
    if(self.dataSource.count == 1) {
        [self.dataSource removeAllObjects];
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/localFile"];
        NSArray *array = [self getAllDirAndFile:path];
        [self.dataSource addObject:array];
    }
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger number = [self getCurFileArray].count;
    return number;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileTableViewCellIdentifier"];
    cell.textLabel.text = [self getFileName:indexPath.row];
    if([self isDirectory:[self getFilePath:indexPath.row]]) {
        cell.detailTextLabel.text = @"目录";
    } else {
        cell.detailTextLabel.text = @"文件";
    }
    cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *path = [self getFilePath:indexPath.row];
    if ([self isDirectory:path]) {
        NSArray *array = [self getAllDirAndFile:path];
        [self.dataSource addObject:array];
        [self.tableView reloadData];
    } else {
        [self performSegueWithIdentifier:@"ToWebView" sender:path];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ToWebView"]) {
        //gara 这里需要设置storeId
        WebViewController *vc = [segue destinationViewController];
        vc.path = sender;
    }
}

- (NSArray*)getAllDirAndFile:(NSString*)path {
    NSArray *fileArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    if (!fileArray) {
        fileArray = @[];
    }
    NSMutableArray *pathMutableArray = [[NSMutableArray alloc] init];
    for (NSString *file in fileArray) {
        [pathMutableArray addObject:[path stringByAppendingPathComponent:file]];
    }
    return pathMutableArray;
}

- (BOOL)isDirectory:(NSString*)path {
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    return isDir;
}

- (NSString*)getFileName:(NSInteger)row {
    NSString *path = [self getFilePath:row];
    return path.lastPathComponent;
}

- (NSString*)getFilePath:(NSInteger)row {
    NSArray *array = [self getCurFileArray];
    if(row < array.count) {
        NSString *path = array[row];
        return path;
    }
    return nil;
}

- (NSArray*)getCurFileArray {
    NSArray *array = [self.dataSource lastObject];
    return array;
}

@end
