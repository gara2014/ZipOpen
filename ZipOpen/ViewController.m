//
//  ViewController.m
//  ZipOpen
//
//  Created by gara on 2017/9/12.
//  Copyright © 2017年 gara. All rights reserved.
//

#import "ViewController.h"
#import "WebViewController.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *dataSource;
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentsOfDirectionChanged:) name:@"contentsOfDirectionChanged" object:nil];
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

- (void)contentsOfDirectionChanged:(id)sender {
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
