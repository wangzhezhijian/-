//
//  WKDownloaderManager.h
//  下载管理器
//
//  Created by AISION on 2018/6/1.
//  Copyright © 2018年 zhongkai wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WKDownloaderManager : NSObject
+ (instancetype)shareDownloaderManager;
/**下载*/
- (void)downloadWithURL:(NSURL *)url Progress:(void(^)(float progress))progress completion:(void(^)(NSString * filePath))completion failed:(void(^)(NSString*errorMsg))failed;
/**暂停下载*/
- (void)pauserWithURL:(NSURL *)url;
@end
