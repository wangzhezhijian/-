//
//  WKDownloader.m
//  下载管理器
//
//  Created by AISION on 2018/6/1.
//  Copyright © 2018年 zhongkai wang. All rights reserved.
//

#import "WKDownloader.h"
#define kTimeOut 20.0

@interface WKDownloader ()<NSURLConnectionDataDelegate>
/**文件输出流*/
@property(nonatomic,strong)NSOutputStream * fileStream;
/**文件路径*/
@property(copy,nonatomic)NSString *filePath;
/**下载文件的URL*/
@property(nonatomic,strong)NSURL *downloadURL;
/**网络文件总大小*/
@property(assign,nonatomic)long long expectedContentLength;
/**本地文件总大小*/
@property(assign,nonatomic)long long currentLength;
/**下载的连接*/
@property(nonatomic,strong)NSURLConnection * downloadConnection;
/**下载的RunLoop*/
@property(assign,nonatomic)CFRunLoopRef downloadRunloop;

//-----------------------BLOCK属性---------------
@property(copy,nonatomic)void(^progressBlock)(float);
@property(copy,nonatomic)void(^completionBlock)(NSString *);
@property(copy,nonatomic)void(^failedBlock)(NSString *);
@end


@implementation WKDownloader
- (void)downloadWithURL:(NSURL *)url Progress:(void(^)(float progress))progress completion:(void(^)(NSString *filePath))completion failed:(void(^)(NSString*errorMsg))failed
{
    //0.保存属性
    self.downloadURL = url;
    self.progressBlock = progress;
    self.completionBlock = completion;
    self.failedBlock = failed;
    
    // 1.检查服务器上的文件大小
    [self severFileInfoWithURL:url];
    NSLog(@"%lld   %@",self.expectedContentLength,self.filePath);
    // 2.检查本地文件大小
    if (![self checkLocalFileInfo]) {
        NSLog(@"文件已经下载完毕");
        return;
    }
    // 3.如果需要，从服务器开始下载
    NSLog(@"从我们的%lld下载文件",self.currentLength);
    
    
}
- (void)pause
{
    //取消当前的连接
    [self.downloadConnection cancel];
}
#pragma mark--<下载文件>
// 从self.currentLength 开始下载文件
- (void)downloadFile{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //1.建立请求
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.downloadURL cachePolicy:1 timeoutInterval:kTimeOut];
        //设置下载的字节范围，从self.currentLength 开始之后所有的字节
        NSString *rangeStr = [NSString stringWithFormat:@"byte=%lld-",self.currentLength];
        //设置请求头字段
        [request setValue:rangeStr forHTTPHeaderField:@"Range"];
        //2.开始网络连接
        self.downloadConnection = [NSURLConnection connectionWithRequest:request delegate:self];
        //3.启动完了连接
        [self.downloadConnection start];
        //4.利用运行循环实现多线程不被回收
        self.downloadRunloop = CFRunLoopGetCurrent();
        CFRunLoopRun();
    });
}

// 检查服务器文件大小
- (void)severFileInfoWithURL:(NSURL *)url{
    // 1.请求
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:1 timeoutInterval:kTimeOut];
    request.HTTPMethod = @"HEAD";
    // 2.建立网络连接
    NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:NULL];
    //3.记录服务器文件的信息
    //3.1文件长度
    self.expectedContentLength = response.expectedContentLength;
    //3.2建议保存的文件名，将在的文件保存在tmp,系统会自动回收
    self.filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:response.suggestedFilename];
    return;
}
#pragma mark - <私有方法>
/**
 * 检查本地文件信息 --> 判断是否需要下载
 *
 * @return YES 需要下载，NO 不需要下载
 */
- (BOOL)checkLocalFileInfo
{
    long long fileSize = 0;
    //1.文件是否存在
    if ([[NSFileManager defaultManager]fileExistsAtPath:self.filePath]) {
        //获取文件大小
        NSDictionary *attributes = [[NSFileManager defaultManager]attributesOfItemAtPath:self.filePath error:NULL];
        // filesize = [attribute[NSFilesize]longLongSize]
        // 利用分类方法获取文件大小
        fileSize = [attributes fileSize];
    }
    /**
     如果大小小于服务器的大小，从本地文件长度开始下载！！！(续传)
     如果大小等于服务器的大小，认为文件已经下载完毕
     如果大小大于服务器的大小，直接干掉，重新下载
     */
    //大于服务器的文件
    if(fileSize > self.expectedContentLength){
        //删除这个文件
        [[NSFileManager defaultManager]removeItemAtPath:self.filePath error:NULL];
        fileSize = 0;
    }
    //是否文件和服务器的文件大小一样
    self.currentLength = fileSize;
    if (fileSize == self.expectedContentLength) {
        if (self.completionBlock) {
            self.completionBlock(self.filePath);
        }
        return NO;
    }
    return YES;
}
#pragma mark--<NSURLConnectionDelegate>
//1.接受到服务器的响应
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // 打开输出流
    self.fileStream = [[NSOutputStream alloc]initToFileAtPath:self.filePath append:YES];
    [self.fileStream open];
}
//2.接收到数据，用输出流拼接，计算下载进度
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //追加数据
    [self.fileStream write:data.bytes maxLength:data.length];
    //记录文件的长度
    self.currentLength += data.length;
    
    float progress = (float)self.currentLength/self.expectedContentLength;
    //判断block是否存在
    if (self.progressBlock) {
        self.progressBlock(progress);
    }
}
//3.下载完毕
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //关闭流
    [self.fileStream close];
    //停止运行循环
    CFRunLoopStop(self.downloadRunloop);
    //判断Block是否存在
    if (self.completionBlock) {
        //主线程回调
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionBlock(self.filePath);
        });
    }
}
//4.出错
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    //关闭流
    [self.fileStream close];
    //停止运行循环
    CFRunLoopStop(self.downloadRunloop);
    //判断BLOCK是否存在
    if (self.failedBlock) {
        self.failedBlock(error.localizedDescription);
    }
    NSLog(@"%@",error.localizedDescription);
}




@end
