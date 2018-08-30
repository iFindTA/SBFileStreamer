//
//  SBFile.m
//  SBFileStreamer
//
//  Created by nanhu on 2018/8/21.
//  Copyright © 2018年 nanhu. All rights reserved.
//

#import "SBFile.h"
#import "SBFileStreamer.h"
#import <AFNetworking/AFNetworking.h>

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
    //lyrics
    mimes = @[@"lrc", @"trc", @"krc", @"qrc", @"ksc", @"kaj"];
    for (NSString *v in mimes) {
        if ([v isEqualToString:ext]) {
            dir = @"lyrics";
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

@interface SBFile()

@property (nonatomic, strong) NSFileHandle *fileHandler;
//@property (nonatomic, strong) AFURLSessionManager *manager;

/**
 离线task
 */
@property (nonatomic, getter=fetchTask, nullable) NSURLSessionDataTask *task;

@end

@implementation SBFile

- (id)init {
    self = [super init];
    if (self) {
        _state = SBFileStateIdle;
        _cloud = SBFileCloudQiNiu;
        _direction = SBFileDirectionDown;
        _progress = 0.f;
        _totalLength = 0;
    }
    return self;
}

+ (instancetype)fileWithUri:(NSString *)uri key:(NSString *)key storage:(SBFileCloud)from owner:(NSString *)uid {
    SBFile *file = [[SBFile alloc] init];
    file.key = key;
    file.uri = uri;
    file.owner = uid;
    file.cloud = from;
    return file;
}

+ (NSArray *)whc_IgnorePropertys {
    return @[@"task",
             @"error",
             @"ossTask",
             @"manager",
             @"progress",
             @"fileHandler",
             @"currentLength",
             @"stateCallback",
             @"progressCallback"];
}

+ (NSString *)whc_SqliteVersion {
    return @"1.3";
}

#pragma mark --- getter
- (AFHTTPSessionManager *)fetchManager {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    AFJSONRequestSerializer *serializer = [AFJSONRequestSerializer serializer];
    [serializer setStringEncoding:NSUTF8StringEncoding];
    manager.requestSerializer=serializer;
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    return manager;
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
//        if (self.owner.length > 0) {
//            fullPath = [fullPath stringByAppendingPathComponent:self.owner];
//        }
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
        NSAssert(self.uri.length > 0 && self.key.length > 0, @"uri or key was nil!");
        //prepare exist size
        self.currentLength = [self fetchCachedSize];
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-", self.currentLength];
        //assemble uri for obj
        NSURL *url = [NSURL URLWithString:self.uri];
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

#pragma mark --- OSS Logics

@end
