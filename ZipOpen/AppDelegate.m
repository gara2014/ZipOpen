//
//  AppDelegate.m
//  ZipOpen
//
//  Created by gara on 2017/9/12.
//  Copyright © 2017年 gara. All rights reserved.
//

#import "AppDelegate.h"
#import "ZipArchive.h"
#import "NSString+URL.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(id)annotation
{
    if (self.window) {
        if (url) {
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
                NSString *path = srcPath;
                if (path.length > 0) {
                    ZipArchive* zip = [[ZipArchive alloc] init];
                    zip.stringEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
                    BOOL suc = [zip UnzipOpenFile:path];
                    if (suc) {
                        NSString *outputDir = [dstPath stringByDeletingPathExtension];
                        if (outputDir.length > 0) {
                            NSString *outputDirTemp = [outputDir stringByAppendingString:@"_temp"];
                            if([zip UnzipFileTo:outputDirTemp overWrite:YES]) {
                                
                                if ([[NSFileManager defaultManager] fileExistsAtPath:outputDir]) {
                                    [[NSFileManager defaultManager] removeItemAtPath:outputDir error:nil];
                                }
                                suc = [[NSFileManager defaultManager] moveItemAtPath:outputDirTemp toPath:outputDir error:nil];
                                //return suc;
                            }
                            else {
                                //打开失败，删掉缓存文件
                                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                            }
                        }
                    }
                    else {
                        //打开失败，删掉缓存文件
                        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                    }
                }
            } else {
                NSData *data = [NSData dataWithContentsOfURL:url];
                NSError *error = nil;
                [data writeToFile:dstPath options:NSDataWritingAtomic error:&error];
                NSLog(@"success:%@", error);
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"contentsOfDirectionChanged" object:nil];
        }
    }
    return YES;
}

@end
