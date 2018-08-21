//
//  SBFile.h
//  SBFileStreamer
//
//  Created by nanhu on 2018/8/21.
//  Copyright © 2018年 nanhu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <WHC_ModelSqliteKit/WHC_ModelSqlite.h>

/**
 文件传输状态
 */
typedef enum : NSUInteger {
    SBFileStateIdle                                 =   1   <<  0,  //等待
    SBFileStateInTransit                            =   1   <<  1,  //传输中（上行/下行）
    SBFileStateFinished                             =   1   <<  2,  //完成
    SBFileStateFailed                               =   1   <<  3,  //失败
    SBFileStatePause                                =   1   <<  4,  //暂停
} SBFileState;
/**
 文件传输状态远端存储类型
 */
typedef enum : NSUInteger {
    SBFileCloudQiNiu                                =   1   <<  0,  //七牛OSS
    SBFileCloudAliYun                               =   1   <<  1,  //阿里云OSS
} SBFileCloud;
/**
 文件传输类型（上行/下行）
 */
typedef enum : NSUInteger {
    SBFileDirectionUp                                =   1   <<  0,  //上行
    SBFileDirectionDown                              =   1   <<  1,  //下行
} SBFileDirection;


/**
 file model
 */
@interface SBFile: NSObject<WHC_SqliteInfo>

/**
 file name 对应所属平台的key值
 */
@property (nonatomic, copy, nonnull) NSString *key;

/**
 file uri 如七牛云存储的全路径
 */
@property (nonatomic, copy, nonnull) NSString *uri;

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
 file cloud type, default is qiniu
 */
@property (nonatomic, assign) SBFileCloud cloud;

/**
 file type, default is upload
 */
@property (nonatomic, assign) SBFileDirection direction;

/**
 file size
 */
@property (nonatomic, assign) NSUInteger totalLength;
@property (nonatomic, assign) NSUInteger currentLength;

/**
 传输进度回调（weak file obj）
 */
@property (nonatomic, copy) void(^_Nullable progressCallback)(SBFile *_Nonnull) NS_UNAVAILABLE;

/**
 传输状态回调（weak file obj）
 */
@property (nonatomic, copy) void(^_Nullable stateCallback)(SBFile *_Nonnull);

//失败 or 成功
@property (nonatomic, strong, nullable) NSError *error;

/**
 instance method for create file-download!

 @param uri for full-path
 @param key for file obj
 @param from for source type
 @param uid for owner
 @return the file
 */
+ (instancetype _Nonnull)fileWithUri:(NSString *_Nonnull)uri key:(NSString *_Nonnull)key storage:(SBFileCloud)from owner:(NSString *_Nonnull)uid;

/**
 fetch size for local-cached file
 */
- (NSUInteger)fetchCachedSize;

/**
 resume or pause
 */
- (void)resume:(BOOL)r;

/**
 cancel task
 */
- (void)cancel;

@end
