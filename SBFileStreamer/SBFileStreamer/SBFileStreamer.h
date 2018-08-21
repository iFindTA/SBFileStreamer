//
//  SBFileStreamer.h
//  SBFileStreamer
//
//  Created by nanhu on 2018/8/20.
//  Copyright © 2018年 nanhu. All rights reserved.
//

#import "SBFile.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SBStreamConfigure: NSObject
#pragma mark --- configure for OSS

/**
 eg.oss-cn-shanghai.aliyuncs.com
 */
@property (nonatomic, copy) NSString *endPoint;

/**
 online sts-token authorization
 */
@property (nonatomic, copy) NSString *stsAuthUri;

/**
 bucket for oss
 */
@property (nonatomic, copy) NSString *bucket;

#pragma mark --- configure for qiniu

/**
 base uri for qiniu
 */
@property (nonatomic, copy) NSString *qnToken;

@end

/**
 file transfer
 */
@interface SBFileStreamer : NSObject
- (id)init NS_UNAVAILABLE;

/**
 configure base params
 */
+ (void)configure:(SBStreamConfigure *)configure;

/**
 singleton mode
 */
+ (instancetype)shared;

/**
 暂停任务（下载/上传）
 */
- (void)pause:(NSString *)key;

/**
 继续任务（下载/上传）
 */
- (void)resume:(NSString *)key;

/**
 取消任务（下载/上传）,key 集合
 */
- (void)cancel:(NSArray<NSString *> *)keys;

/**
 加电自检，开始传输未完成的任务队列
 */
- (void)powerUpAutoCheck:(NSString *)uid;

/**
 添加到下载队列
 */
- (void)append2Download:(NSArray<SBFile*> *)files;

#pragma mark ---- getter

/**
 获取下载队列中的任务列表
 */
- (NSArray<SBFile*>* _Nullable)fetchDownloadTasks4Owner:(NSString *_Nonnull)uid;
- (NSArray<SBFile*>* _Nullable)fetchDownloadTasks4:(SBFileState)state owner:(NSString *_Nonnull)uid;

///**
// oss client
// */
//- (OSSClient * _Nullable)ossClient;
//
///**
// oss bucket name
// */
//- (NSString * _Nullable)ossBucket;

@end

NS_ASSUME_NONNULL_END
