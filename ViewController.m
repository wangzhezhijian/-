//
//  ViewController.m
//  下载管理器
//
//  Created by AISION on 2018/6/1.
//  Copyright © 2018年 zhongkai wang. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)pause:(id)sender {
    
    [[HKDownloaderManager shareDownloaderManager] pauserWithURL:self.url];
}


- (IBAction)start{
    NSURL * url = [NSURL URLWithString:@"http://sw.bos.baidu.com/sw-search-sp/software/50045684f7da6/QQ_mac_5.4.1.dmg"];
    self.url = url;
    [[HKDownloaderManager shareDownloaderManager] downloadWithURL:url Progress:^(float progress) {
        NSLog(@"--->%f  %@",progress,[NSThread currentThread]);
    } completion:^(NSString *filePath) {
        //下载成功了
        NSLog(@"下载完成了 %@ %@",filePath,[NSThread currentThread]);
        
    } failed:^(NSString *errorMsg) {
        NSLog(@"======>  %@",errorMsg);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
