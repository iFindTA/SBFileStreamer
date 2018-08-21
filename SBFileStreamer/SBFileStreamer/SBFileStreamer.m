//
//  SBFileStreamer.m
//  SBFileStreamer
//
//  Created by nanhu on 2018/8/20.
//  Copyright © 2018年 nanhu. All rights reserved.
//

#import "SBFileStreamer.h"

#pragma mark -----> SBKit >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
@interface SBKit: NSObject
@end
@implementation SBKit
+ (NSString *)sandbox {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true);
    NSString *documentPath = paths.firstObject;
    return documentPath;
}
+ (NSString *)fetchDir4FileExtention:(NSString *)ext {
    //默认
    NSString *dir = @"files";
    //video
    NSArray <NSString*>*mimes = @[@"mp4", @"mov", @"avi"];
    for (NSString *v in mimes) {
        if ([v isEqualToString:ext]) {
            dir = @"videos";
            break;
        }
    }
    //audio
    mimes = @[@"mp3", @"wma", @"ogg", @"wav", @"aac"];
    for (NSString *a in mimes) {
        if ([a isEqualToString:ext]) {
            dir = @"audios";
            break;
        }
    }
    //images
    mimes = @[@"jpg", @"jpeg", @"png", @"gif", @"bmp", @"tiff", @"ai", @"cdr", @"eps"];
    for (NSString *a in mimes) {
        if ([a isEqualToString:ext]) {
            dir = @"images";
            break;
        }
    }
    return dir;
}
@end
#pragma mark -----> 对象模型 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

@interface SBFile()

@property (nonatomic, strong) NSFileHandle *fileHandler;
//@property (nonatomic, strong) AFURLSessionManager *manager;

@end

@implementation SBFile

- (id)init {
    self = [super init];
    if (self) {
        _type = SBFileTypeUpload;
        _state = SBFileStateIdle;
        _progress = 0.f;
        _totalLength = 0;
    }
    return self;
}

+ (instancetype)fileWithBaseUri:(NSString *)uri with:(NSString *)key owner:(NSString *)uid type:(SBFileType)type {
    SBFile *file = [[SBFile alloc] init];
    file.key = key;
    file.owner = uid;
    file.type = type;
    file.baseUri = uri;
    return file;
}

+ (NSArray *)whc_IgnorePropertys {
    return @[@"task",
             @"error",
             @"manager",
             @"progress",
             @"fileHandler",
             @"currentLength",
             @"stateCallback",
             @"progressCallback"];
}


#pragma mark --- getter
//- (AFHTTPSessionManager *)manager {
//    if (!_manager) {
//        NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
//        _manager = [AFHTTPSessionManager manager];
//    }
//    return _manager;
//}
- (AFHTTPSessionManager *)fetchManager {
    return [AFHTTPSessionManager manager];
}
- (NSFileHandle *)fileHandler {
    if (!_fileHandler) {
        NSFileManager *m = [NSFileManager defaultManager];
        if (![m fileExistsAtPath:self.destPath]) {
            //如果没有下载文件的话，就创建一个文件。如果有下载文件的话，则不用重新创建(不然会覆盖掉之前的文件)
            [m createFileAtPath:self.destPath contents:nil attributes:nil];
        }
        _fileHandler = [NSFileHandle fileHandleForWritingAtPath:self.destPath];
    }
    return _fileHandler;
}
- (NSString *)destPath {
    if (!_destPath) {
        NSAssert(self.key.length > 0, @"empty key!");
        NSString *ext = [self.key pathExtension];
        NSString *dir = [SBKit fetchDir4FileExtention:ext];
        NSString *sandBox = [SBKit sandbox];
        NSString *fullPath = [sandBox stringByAppendingPathComponent:dir];
        if (self.owner.length > 0) {
            fullPath = [fullPath stringByAppendingPathComponent:self.owner];
        }
        NSError *err;
        NSFileManager *m = [NSFileManager defaultManager];
        if (![m fileExistsAtPath:fullPath]) {
            [m createDirectoryAtPath:fullPath withIntermediateDirectories:true attributes:nil error:&err];
            if (err) {
                NSLog(@"创建用户下载目录失败!------%@", err.description);
            }
        }
        fullPath = [fullPath stringByAppendingPathComponent:self.key];
        _destPath = fullPath.copy;
        NSLog(@"assemble file dest full path:%@", fullPath);
    }
    return _destPath;
}
- (NSUInteger)fetchCachedSize {
    NSUInteger size = 0;
    NSFileManager *m = [NSFileManager defaultManager];
    if ([m fileExistsAtPath:self.destPath]) {
        NSError *err;
        NSDictionary*attr = [m attributesOfItemAtPath:self.destPath error:&err];
        if (!err && attr) {
            size = [attr fileSize];
        }
    }
    return size;
}
- (NSURLSessionDataTask *)fetchTask {
    if (!_task) {
        NSAssert(self.baseUri.length > 0 && self.key.length > 0, @"uri or key was nil!");
        //prepare exist size
        self.currentLength = [self fetchCachedSize];
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-", self.currentLength];
        //assemble uri for obj
        NSString *uri = [NSString stringWithFormat:@"%@/%@", self.baseUri, self.key];
        NSURL *url = [NSURL URLWithString:uri];
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
        [req setValue:range forHTTPHeaderField:@"Range"];
        //set callback
        
        //AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:cfg];
        __weak typeof (self) this = self;AFHTTPSessionManager *manager = [self fetchManager];
        //completed callback
        _task = [manager dataTaskWithRequest:req uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            NSLog(@"download did completed!---error:%@", error.localizedDescription);
            //close file handle
            [this.fileHandler closeFile];
            this.fileHandler = nil;
            
            //callback
            this.error = error;
            this.state = (error == nil) ? SBFileStateFinished : SBFileStateFailed;
            if (this.stateCallback) {
                this.stateCallback(this);
            }
        }];
        //response callback
        [manager setDataTaskDidReceiveResponseBlock:^NSURLSessionResponseDisposition(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSURLResponse * _Nonnull response) {
            NSLog(@"download did response!");
            //fetch total length
            this.totalLength = response.expectedContentLength + this.currentLength;
            NSLog(@"file total size:%zd", this.totalLength);
            //callback
            this.state = SBFileStateInTransit;
            if (this.stateCallback) {
                this.stateCallback(this);
            }
            return NSURLSessionResponseAllow;
        }];
        //did received data callback
        [manager setDataTaskDidReceiveDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data) {
            NSLog(@"download did received data....");
            //write data to file end
            [this.fileHandler seekToEndOfFile];
            [this.fileHandler writeData:data];
            //update current length and progress
            this.currentLength += data.length;
            CGFloat percent = 1.0 * this.currentLength / this.totalLength;
            if (this.totalLength == 0) {
                percent = 0.f;
            }
            this.progress = percent;
            NSLog(@"percenter:%.2f", percent);
            if (this.state != SBFileStateInTransit) {
                this.state = SBFileStateInTransit;
                if (this.stateCallback) {
                    this.stateCallback(this);
                }
            }
        }];
    }
    return _task;
}

/**
 继续/暂停
 */
- (void)resume:(BOOL)r {
    self.state = r ? SBFileStateInTransit : SBFileStatePause;
    if (self.stateCallback) {
        __weak typeof (self) this = self;
        self.stateCallback(this);
    }
    if (r) {
        [self.task resume];
    } else {
        [self.task suspend];
    }
}

- (void)cancel {
    [self.task cancel];
}

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

static SBFileStreamer *instance = nil;

@implementation SBFileStreamer
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
        f.stateCallback = ^(SBFile *f){
            [this updateState:f];
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
    
    //移除队列
    if (f.state & (SBFileStateFinished | SBFileStateFailed)) {
        @synchronized(self.downloadQueues){
            [self.downloadQueues enumerateObjectsUsingBlock:^(SBFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.key == f.key) {
                    [self.downloadQueues removeObject:obj];
                    *stop = true;
                }
            }];
        }
        [self next];
    } else if (f.state & SBFileStatePause) {
        //暂定后继续下一个
        [self next];
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

@end
