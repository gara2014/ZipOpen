//
//  WebViewController.m
//  ZipOpen
//
//  Created by gara on 2017/9/12.
//  Copyright © 2017年 gara. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()

@property (nonatomic, strong) IBOutlet UIWebView *webView;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString *title = [self.path lastPathComponent];
    title = [title stringByDeletingPathExtension];
    self.title = title;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:self.path]];
    [self.webView loadRequest:request];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
