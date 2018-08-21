//
//  SBFileStreamer.h
//  SBFileStreamer
//
//  Created by nanhu on 2018/8/20.
//  Copyright © 2018年 nanhu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import <WHC_ModelSqliteKit/WHC_ModelSqlite.h>

typedef enum : NSUInteger {
    SBFileStateIdle                                 =   1   <<  0,  //等待
    SBFileStatePreTreat                             =   1   <<  1,  //预处理
    SBFileStateInTransit                            =   1   <<  2,  //传输中（上行/下行）
    SBFileStateFinished                             =   1   <<  3,  //完成
    SBFileStateFailed                               =   1   <<  4,  //失败
    SBFileStatePause                                =   1   <<  5,  //暂停
} SBFileState;

typedef enum : NSUInteger {
    SBFileTypeUpload                                =   1   <<  0,  //上传
    SBFileTypeDownload                              =   1   <<  1,  //下载
} SBFileType;

/**
 file model
 */
@interface SBFile: NSObject<WHC_SqliteInfo>

/**
 file name 对应所属平台的key值
 */
@property (nonatomic, copy, nonnull) NSString *key;

/**
 基地址 如七牛基地址
 */
@property (nonatomic, copy, nonnull) NSString *baseUri;

/**
 file 所属者
 */
@property (nonatomic, copy, nonnull) NSString *owner;

/**
 file 真实存储地址
 */
@property (nonatomic, copy, nullable) NSString *destPath;

/**
 file 传输进度
 */
@property (nonatomic, assign) CGFloat progress;

/**
 file state, default is idle
 */
@property (nonatomic, assign) SBFileState state;

/**
 file type, default is upload
 */
@property (nonatomic, assign) SBFileType type;

/**
 file size
 */
@property (nonatomic, assign) NSUInteger totalLength;
@property (nonatomic, assign) NSUInteger currentLength;

/**
 传输进度回调（weak file obj）
 */
@property (nonatomic, copy) void(^progressCallback)(SBFile *) NS_UNAVAILABLE;

/**
 传输状态回调（weak file obj）
 */
@property (nonatomic, copy) void(^stateCallback)(SBFile *);

//失败 or 成功
@property (nonatomic, strong, nullable) NSError *error;

/**
 离线task
 */
@property (nonatomic, getter=fetchTask) NSURLSessionDataTask *task;

/**
 factory method
 
 @param uid for diff user
 @return file object
 */
+ (instancetype)fileWithBaseUri:(NSString *)uri with:(NSString *)key owner:(NSString *)uid type:(SBFileType)type;

/**
 fetch size for local-cached file
 */
- (NSUInteger)fetchCachedSize;

@end


/**
 file transfer
 */
@interface SBFileStreamer : NSObject
- (id)init NS_UNAVAILABLE;

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
 singleton mode
 */
+ (instancetype)shared;

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
- (NSArray<SBFile*>* _Nullable)fetchDownloadTasks4Owner:(NSString *)uid;
- (NSArray<SBFile*>* _Nullable)fetchDownloadTasks4:(SBFileState)state owner:(NSString *)uid;
@end
