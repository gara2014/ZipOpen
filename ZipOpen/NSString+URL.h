//
//  NSString+URL.h
//  ZipOpen
//
//  Created by gara on 2017/9/12.
//  Copyright © 2017年 gara. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (URL)

/**
 *  URLEncode
 */
- (NSString *)URLEncodedString;

/**
 *  URLDecode
 */
-(NSString *)URLDecodedString;

@end
