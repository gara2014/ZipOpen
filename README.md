# Zip Open
## 为什么是Zip Open
* 我们通过微信第三方IM工具接收到zip压缩文件后，IM工具一般没有解压缩功能，导致无法在上面解压查看。<br><br>
* 第三方工具可以用过Zip Open打开解压zip文件，然后在Zip Open里浏览解压后的文件。<br>

## 实现方法
1、首先修改info.plist文件，添加Document Types字段
```C
<key>CFBundleDocumentTypes</key>
	<array>
		<dict>
			<key>LSItemContentTypes</key>
			<array>
				<string>org.openxmlformats.openxml</string>
			</array>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>CFBundleTypeName</key>
			<string>officeopenxml</string>
		</dict>
		<dict>
			<key>LSItemContentTypes</key>
			<array>
				<string>public.data</string>
			</array>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>CFBundleTypeName</key>
			<string>data</string>
		</dict>
		<dict>
			<key>LSItemContentTypes</key>
			<array>
				<string>com.microsoft.powerpoint.ppt</string>
			</array>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>CFBundleTypeName</key>
			<string>ppt</string>
		</dict>
		<dict>
			<key>LSItemContentTypes</key>
			<array>
				<string>com.microsoft.word.doc</string>
			</array>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>CFBundleTypeName</key>
			<string>doc</string>
		</dict>
		<dict>
			<key>LSItemContentTypes</key>
			<array>
				<string>com.microsoft.excel.xls</string>
			</array>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>CFBundleTypeName</key>
			<string>xls</string>
		</dict>
		<dict>
			<key>LSItemContentTypes</key>
			<array>
				<string>com.adobe.pdf</string>
			</array>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>CFBundleTypeName</key>
			<string>pdf</string>
		</dict>
		<dict>
			<key>LSItemContentTypes</key>
			<array>
				<string>org.gnu.gnu-tar-archive</string>
			</array>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>CFBundleTypeName</key>
			<string>archive</string>
		</dict>
		<dict>
			<key>LSItemContentTypes</key>
			<array>
				<string>public.audiovisual-content</string>
			</array>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>CFBundleTypeName</key>
			<string>audivideo</string>
		</dict>
		<dict>
			<key>LSItemContentTypes</key>
			<array>
				<string>public.image</string>
			</array>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>CFBundleTypeName</key>
			<string>image</string>
		</dict>
		<dict>
			<key>LSItemContentTypes</key>
			<array>
				<string>public.text</string>
			</array>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>CFBundleTypeName</key>
			<string>txt</string>
		</dict>
	</array>
```
2、接着在AppDelegate实现AppDelegate协议
```C
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
```
3、在ViewController里枚举所有文件
```C
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
```
4、在WebViewController里，使用WebView打开文件
```C
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString *title = [self.path lastPathComponent];
    title = [title stringByDeletingPathExtension];
    self.title = title;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:self.path]];
    [self.webView loadRequest:request];
}
```

## 截图
第三方应用中：
![](https://github.com/gara2014/ZipOpen/raw/master/pics/IMG_5179.PNG)

ZipOpen文件列表：
![](https://github.com/gara2014/ZipOpen/raw/master/pics/IMG_5180.PNG)

ZipOpen WebView：
![](https://github.com/gara2014/ZipOpen/raw/master/pics/IMG_5181.PNG)

## 开发环境
XCode 8.2

## 苹果开发文档
可以在 XCode 里 "Documentaction And API Reference" 里搜索 "Document Interaction Programming Topics for iOS"
