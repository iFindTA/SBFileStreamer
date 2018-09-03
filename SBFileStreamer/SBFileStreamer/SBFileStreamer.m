//
//  SBFileStreamer.m
//  SBFileStreamer
//
//  Created by nanhu on 2018/8/20.
//  Copyright © 2018年 nanhu. All rights reserved.
//

#import "SBFile.h"
#import "SBFileStreamer.h"

#pragma mark -----> 文件传输配置 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
@implementation SBStreamConfigure

@end
#pragma mark -----> 文件传输 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

@interface SBFileStreamer()

/**
 下载队列
 */
@property (nonatomic, strong) NSMutableArray<SBFile*>* downloadQueues;

/**
 当前是否有下行的数据流
 */
@property (nonatomic, assign) BOOL isDownStreaming;

@end
static SBStreamConfigure *globalConfigure = nil;
static SBFileStreamer *instance = nil;
//static OSSClient *ossInstance = nil;
@implementation SBFileStreamer
+ (void)configure:(SBStreamConfigure *)configure {
    globalConfigure = configure;
}
+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SBFileStreamer alloc] _init];
    });
    return instance;
}

- (id)_init {
    self = [super init];
    if (self) {
        _isDownStreaming = false;
    }
    return self;
}

#pragma mark --- 加电自检
- (void)powerUpAutoCheck:(NSString *)uid {
    //下行
    [self.downloadQueues removeAllObjects];
    NSArray<SBFile *>*unDones = [self fetchDownloadTasks4Owner:uid];
    [self append2Download:unDones];
}

#pragma mark --- append download
- (void)append2Download:(NSArray<SBFile *> *)files {
    if (files == nil) {
        return;
    }
    //callback
    for (SBFile *f in files) {
        __weak typeof (self) this = self;
//        f.stateCallback = ^(SBFile *f){
//            [this updateState:f];
//        };
        __weak typeof(SBFile)*wkFile = f;
        f.callback = ^{
            [this updateState:wkFile];
        };
        //存储
        NSString *sql = [NSString stringWithFormat:@"key = '%@' AND owner = '%@'", f.key, f.owner];
        if ([WHCSqlite query:[SBFile class] where:sql].count == 0) {
            [WHCSqlite insert:f];
        }
    }
    
    [self.downloadQueues addObjectsFromArray:files];
    [self next];
}

/**
 更新file state
 */
- (void)updateState:(SBFile *)f {
    //更新本地数据库
    NSString *value = [NSString stringWithFormat:@"state = %zd, totalLength = %zd", f.state, f.totalLength];
    NSString *where = [NSString stringWithFormat:@"key = '%@' AND owner = '%@'", f.key, f.owner];
    [WHCSqlite update:[SBFile class] value:value where:where];
    
    //是否继续下一个
    SBFileState shouldState = (SBFileStateFinished | SBFileStateFailed | SBFileStatePause);
    if (f.state & shouldState) {
        [self next];
    }
    //移除队列
    if (f.state & (SBFileStateFinished | SBFileStateFailed)) {
//        @synchronized(self.downloadQueues){
//            [self.downloadQueues enumerateObjectsUsingBlock:^(SBFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                if (obj.key == f.key) {
//                    [self.downloadQueues removeObject:obj];
//                    *stop = true;
//                }
//            }];
//        }
//        [self next];
    }
}

- (SBFile * _Nullable)fetchNext {
    __block SBFile *f;
    @synchronized(self.downloadQueues){
        [self.downloadQueues enumerateObjectsUsingBlock:^(SBFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.state == SBFileStateIdle) {
                f = obj;
                *stop = true;
            }
        }];
    }
    return f;
}

- (void)next {
    SBFile *f = [self fetchNext];
    if (f) {
        _isDownStreaming = true;
        [f resume:true];
    } else {
        _isDownStreaming = false;
        //FIXME:此处可以全局通知下载完成
        NSLog(@"全部下载完成！队列counts:%zd", self.downloadQueues.count);
    }
}

- (void)pause:(NSString *)key {
    @synchronized(self.downloadQueues){
        [self.downloadQueues enumerateObjectsUsingBlock:^(SBFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.key isEqualToString:key]) {
                [obj resume:false];
                *stop = true;
            }
        }];
    }
}
- (void)resume:(NSString *)key {
    @synchronized(self.downloadQueues){
        [self.downloadQueues enumerateObjectsUsingBlock:^(SBFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.key isEqualToString:key]) {
                [obj resume:true];
                *stop = true;
            }
        }];
    }
}
- (void)cancel:(NSArray<NSString *> *)keys {
    for (NSString * k in keys) {
        @synchronized(self.downloadQueues){
            [self.downloadQueues enumerateObjectsUsingBlock:^(SBFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.key isEqualToString:k]) {
                    [obj cancel];
                    [self.downloadQueues removeObject:obj];
                    *stop = true;
                }
            }];
        }
    }
}

#pragma mark --- getter

- (NSMutableArray<SBFile*>*)downloadQueues {
    if (!_downloadQueues) {
        _downloadQueues = [NSMutableArray arrayWithCapacity:0];
    }
    return _downloadQueues;
}

- (NSArray<SBFile*>* _Nullable)fetchDownloadTasks4Owner:(NSString *)uid {
    NSString *sql = [NSString stringWithFormat:@"owner = '%@'", uid];
    NSArray<SBFile*>*tmp = [WHCSqlite query:[SBFile class] where:sql];
    return [self weakReferenceAssociate:tmp];
}

- (NSArray<SBFile*>* _Nullable)fetchDownloadTasks4:(SBFileState)state owner:(NSString *)uid {
    NSString *sql = [NSString stringWithFormat:@"state = %zd AND owner = '%@'", state, uid];
    NSArray<SBFile*>*tmp = [WHCSqlite query:[SBFile class] where:sql];
    return [self weakReferenceAssociate:tmp];
}

- (NSArray<SBFile*>*)weakReferenceAssociate:(NSArray<SBFile*>*)tmps {
    if (tmps.count == 0) {
        return tmps;
    }
    //to add reference
    NSMutableArray<SBFile*>*filters = [NSMutableArray arrayWithArray:tmps];
    NSUInteger counts = filters.count;
    for (int i = 0; i < counts; i++) {
        SBFile *f = filters[i];
        SBFile *ref;
        @synchronized(self.downloadQueues){
            for (SBFile *t in self.downloadQueues) {
                if (t.key == f.key) {
                    __weak typeof(SBFile) *wk = t;
                    ref = wk;
                    break;
                }
            }
        }
        if (ref != nil) {
            [filters replaceObjectAtIndex:i withObject:ref];
        }
    }
    return filters.copy;
}

#pragma mark --- OSS

//- (OSSClient *)ossClient {
//    NSAssert(globalConfigure != nil, @"forget to configure oss!");
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        NSString *endPt = globalConfigure.endPoint;
//        NSString *authUri = globalConfigure.stsAuthUri;
//        OSSAuthCredentialProvider *provider = [[OSSAuthCredentialProvider alloc] initWithAuthServerUrl:authUri];
//        OSSClientConfiguration *cfg = [[OSSClientConfiguration alloc] init];
//        cfg.maxRetryCount = 3;
//        cfg.timeoutIntervalForRequest = 30;
//        cfg.timeoutIntervalForResource = 60*3;//资源传输最长时间
//        ossInstance = [[OSSClient alloc] initWithEndpoint:endPt credentialProvider:provider clientConfiguration:cfg];
//    });
//    return ossInstance;
//}
//- (NSString *)ossBucket {
//    return globalConfigure.bucket;
//}

@end
