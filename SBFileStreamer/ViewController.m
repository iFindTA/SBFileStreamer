//
//  ViewController.m
//  SBFileStreamer
//
//  Created by nanhu on 2018/8/18.
//  Copyright © 2018年 nanhu. All rights reserved.
//

#import "ViewController.h"
#import "SBFileStreamer.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    CGRect bounds = CGRectMake(100, 200, 100, 50);
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = bounds;
    [btn setTitle:@"download" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(testDownload) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    bounds.origin.y += 100;
    btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = bounds;
    [btn setTitle:@"pause" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(testPause) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    bounds.origin.y += 100;
    btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = bounds;
    [btn setTitle:@"resume" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(testResume) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    NSString *owner = @"nanhujiaju";
    NSArray<SBFile*>*tmps = [[SBFileStreamer shared] fetchDownloadTasks4:SBFileStateFailed owner:owner];
    NSLog(@"counts: %zd", tmps.count);
}

- (void)testDownload {
    
//    NSString *uri = @"http://speedtest.tokyo.linode.com/100MB-tokyo.bin";
//    NSString *key = @"100MB-tokyo.bin";
//    NSString *owner = @"nanhujiaju";
    
    NSString *uri = @"http://7xrm04.com2.z0.glb.qiniucdn.com/3bfe46c3621abf2bc89f50969a74c9a2.lrc";
    NSString *key = @"3bfe46c3621abf2bc89f50969a74c9a2.lrc";
    NSString *owner = @"nanhujiaju";
    
    SBFile *file = [SBFile fileWithUri:uri key:key storage:SBFileCloudQiNiu owner:owner];
    [[SBFileStreamer shared] append2Download:@[file]];
}

- (void)testPause {
    NSString *key = @"100MB-tokyo.bin";
    [[SBFileStreamer shared] pause:key];
}

- (void)testResume {
    NSString *key = @"100MB-tokyo.bin";
    [[SBFileStreamer shared] resume:key];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
