//
//  WKDownloaderManager.m
//  下载管理器
//
//  Created by AISION on 2018/6/1.
//  Copyright © 2018年 zhongkai wang. All rights reserved.
//

#import "WKDownloaderManager.h"
#import "WKDownloader.h"

@interface WKDownloaderManager()<NSObject>
/**下载操作的缓冲池*/
@property(nonatomic,strong)NSMutableDictionary*downloaderCache;
/**失败的回调属性*/
@property(copy,nonatomic)void(^failedBlock)(NSString *);
@end


@implementation WKDownloaderManager
-(NSMutableDictionary*)downloaderCache{
    if (!_downloaderCache) {
        _downloaderCache = [NSMutableDictionary dictionary];
    }
    return _downloaderCache;
}
/**
 每次实例化一个WKDownloader 对应一个文件的下载操作！！
 如果才操作没有执行完毕，不需要再次开启！
 解决思路：下载缓冲池
 */
+(instancetype)shareDownloaderManager
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    return instance;
}
/**下载任务*/
- (void)downloadWithURL:(NSURL *)url Progress:(void(^)(float progress))progress completion:(void(^)(NSString * filePath))completion failed:(void(^)(NSString*errorMsg))failed
{
    //0.记录失败的回调代码
    self.failedBlock = failed;
    //1.判断缓冲池是否存在下载任务
    WKDownloader *downloader = self.downloaderCache[url.path];
    if (downloader != nil) {
        NSLog(@"下载操作存在！！");
        return;
    }
    //2.创建新的下载任务
    downloader = [[WKDownloader alloc]init];
    //3.将下载任务保存在缓冲池
    [self.downloaderCache setObject:downloader forKey:url.path];
    //传递block参数
    /**
     下载完成之后清除下载操作
     问题：下载完成是异步的回调
     */
    [downloader downloadWithURL:url Progress:progress completion:^(NSString *filePath) {
       //1.从下载缓冲池中删除下载操作！
        [self.downloaderCache removeObjectForKey:url.path];
        //2.执行调用方法传递的Block
        if (completion) {
            completion(filePath);
        }
    } failed:^(NSString *errorMsg) {
        //1.从下载缓冲池中删除下载操作！
        [self.downloaderCache removeObjectForKey:url.path];
        if (failed) {
            failed(errorMsg);
        }
    }];
}
/**暂停下载*/
- (void)pauserWithURL:(NSURL *)url
{
    //1.通过url获取下载任务
    WKDownloader *download = self.downloaderCache[url.path];
    //1.1判断操作是否存在，如果不存在，提示用户
    if (download == nil) {
        if (self.failedBlock) {
            self.failedBlock(@"操作不存在！");
        }
        return;
    }
    //2.暂停
    [download pause];
    //3.从缓冲池删除
    [self.downloaderCache removeObjectForKey:url.path];
}












@end
