//
//  PlayViewModel.m
//  DanWanPlayer
//
//  Created by JimHuang on 15/12/24.
//  Copyright © 2015年 JimHuang. All rights reserved.
//

#import "PlayViewModel.h"
#import "LocalVideoModel.h"
#import "StreamingVideoModel.h"
#import "LocalVideoModel.h"
#import "MatchViewModel.h"
#import "DanMuChooseViewModel.h"
#import "OpenStreamVideoViewModel.h"

#import "MatchModel.h"

#import "DanmakuNetManager.h"
#import "VideoNetManager.h"

@interface PlayViewModel()
//用户发送的弹幕
@property (strong, nonatomic) NSMutableArray *userDanmaukuArr;
@end

@implementation PlayViewModel
{
    NSMutableOrderedSet *_videos;
}

- (instancetype)init {
    if (self = [super init]) {
        _videos = [UserDefaultManager shareUserDefaultManager].videoListOrderedSet;
    }
    return self;
}

- (NSUInteger)danmakuCount {
    __block NSUInteger count = 0;
    [self.currentVideoModel.danmakuDic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSArray * _Nonnull obj, BOOL * _Nonnull stop) {
        count += obj.count;
    }];
    return count;
}

//- (NSString *)videoNameWithIndex:(NSInteger)index {
//    return [self videoModelWithIndex: index].fileName.length ? [self videoModelWithIndex: index].fileName : @"";
//}

//- (BOOL)showPlayIconWithIndex:(NSInteger)index {
//    return index != self.currentIndex;
//}

//- (NSString *)currentVideoName {
//    return [self videoNameWithIndex: _currentIndex];
//}

- (id<VideoModelProtocol>)currentVideoModel {
    return [self videoModelWithIndex: _currentIndex];
}

- (NSTimeInterval)currentVideoLastVideoTime {
    return [[UserDefaultManager shareUserDefaultManager] videoPlayHistoryWithHash:[self currentVideoModel].md5];
}

//- (NSString *)currentVideoHash {
//    return [self currentVideoModel].md5;
//}

//- (NSURL *)currentVideoURL {
//    return [self videoURLWithIndex: _currentIndex];
//}

- (void)setCurrentIndex:(NSUInteger)currentIndex {
    _currentIndex = self.videos.count ? currentIndex % self.videos.count : 0;
    [UserDefaultManager shareUserDefaultManager].currentVideoModel = self.currentVideoModel;
}

- (void)addVideosModel:(NSArray *)videosModel {
    [_videos addObjectsFromArray:videosModel];
    [self synchronizeVideoList];
}

- (void)removeVideoAtIndex:(NSInteger)index {
    if (index == -1) {
        [_videos removeAllObjects];
    }
    else {
        if (index < self.currentIndex) {
            self.currentIndex--;
        }
        [_videos removeObjectAtIndex:index];
    }
    [self synchronizeVideoList];
}

- (void)synchronizeVideoList {
    [[UserDefaultManager shareUserDefaultManager] setVideoListOrderedSet:_videos];
}

- (void)saveUserDanmaku:(DanmakuDataModel *)danmakuModel {
    if ([self.currentVideoModel isKindOfClass:[LocalVideoModel class]]) {
        LocalVideoModel *vm = (LocalVideoModel *)self.currentVideoModel;
        [self.userDanmaukuArr addObject:danmakuModel];
        [UserDefaultManager saveUserSentDanmakus:self.userDanmaukuArr episodeId:vm.episodeId];
    }
}

- (void)reloadDanmakuWithIndex:(NSInteger)index completionHandler:(reloadDanmakuCallBack)complete {
    id<VideoModelProtocol>videoModel = [self videoModelWithIndex:index];
    if (!videoModel) {
        complete(0, nil, [DanDanPlayErrorModel ErrorWithCode:DanDanPlayErrorTypeVideoNoExist]);
        return;
    }
    if ([videoModel isKindOfClass:[LocalVideoModel class]]) {
        [self reloadDanmakuWithLocalMedia:(LocalVideoModel *)videoModel completionHandler:complete];
    }
    else if ([videoModel isKindOfClass:[StreamingVideoModel class]]) {
        [self reloadDanmakuWithOpenStreamVideoViewModel:(StreamingVideoModel *)videoModel completionHandler:complete];
    }
    else {
        //不是视频
        complete(0, nil, [DanDanPlayErrorModel ErrorWithCode:DanDanPlayErrorTypeVideoNoExist]);
    }
    
}

- (void)setVideos:(NSArray<id<VideoModelProtocol>> *)videos {
    _videos = [NSMutableOrderedSet orderedSetWithArray:videos];
    [self synchronizeVideoList];
}

- (NSArray<id<VideoModelProtocol>> *)videos {
    if (_videos == nil) {
        _videos = [UserDefaultManager shareUserDefaultManager].videoListOrderedSet;
    }
    return _videos.array;
}

//- (NSURL *)videoURLWithIndex:(NSInteger)index {
//    return [self videoModelWithIndex: index].fileURL;
//}

- (id<VideoModelProtocol>)videoModelWithIndex:(NSUInteger)index {
    return index < self.videos.count ? self.videos[index] : nil;
}

#pragma mark - 私有方法
- (void)reloadDanmakuWithLocalMedia:(LocalVideoModel *)media completionHandler:(reloadDanmakuCallBack)complete {
    if (![[NSFileManager defaultManager] fileExistsAtPath:media.fileURL.path]) {
        complete(0, nil, [DanDanPlayErrorModel ErrorWithCode:DanDanPlayErrorTypeVideoNoExist]);
        return;
    }
    
    MatchViewModel *vm = [[MatchViewModel alloc] init];
    vm.videoModel = media;
    [vm refreshWithCompletionHandler:^(DanDanPlayErrorModel *error, MatchDataModel *dataModel) {
        //episodeId存在 说明精确匹配
        if (dataModel.episodeId) {
            complete(0.5, nil, error);
            media.episodeId = dataModel.episodeId;
            DanMuChooseViewModel *vm = [[DanMuChooseViewModel alloc] init];
            vm.videoId = dataModel.episodeId;
            //搜索弹幕
            [vm refreshCompletionHandler:^(DanDanPlayErrorModel *error) {
                //判断官方弹幕是否为空
                if (!error) {
                    media.matchTitle = [NSString stringWithFormat:@"%@-%@", dataModel.animeTitle, dataModel.episodeTitle];
                    complete(1, media, error);
                }
                else {
                    //快速匹配失败
                    complete(0, nil, [DanDanPlayErrorModel ErrorWithCode:DanDanPlayErrorTypeNoMatchDanmaku]);
                }
            }];
        }
        else {
            //快速匹配失败
            complete(0, nil, [DanDanPlayErrorModel ErrorWithCode:DanDanPlayErrorTypeNoMatchDanmaku]);
            media.episodeId = nil;
        }
    }];
}

- (void)reloadDanmakuWithOpenStreamVideoViewModel:(StreamingVideoModel *)media completionHandler:(reloadDanmakuCallBack)complete {
    media.episodeId = nil;
    NSInteger index = [self.videos indexOfObject:media];
    if (!media.danmaku.length) {
        complete(0, nil, [DanDanPlayErrorModel ErrorWithCode:DanDanPlayErrorTypeNoMatchDanmaku]);
        return;
    }
    complete(0.5, nil, nil);
    
    //没有请求过的视频 视频数组都为空
    if ([media URLsCountWithQuality:StreamingVideoQualityHigh] == 0 && [media URLsCountWithQuality:StreamingVideoQualityLow] == 0) {
        [[[OpenStreamVideoViewModel alloc] init] getVideoURLAndDanmakuForVideoName:media.fileName danmaku:media.danmaku danmakuSource:media.danmakuSource completionHandler:^(StreamingVideoModel *videoModel, DanDanPlayErrorModel *error) {
            if (videoModel) {
                _videos[index] = videoModel;
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"START_PLAY" object:@[videoModel]];
                complete(1, videoModel, error);
            }
            else {
                complete(0, nil, [DanDanPlayErrorModel ErrorWithCode:DanDanPlayErrorTypeNoMatchDanmaku]);
            }
        }];
    }
    else {
        if (media.danmakuDic.count) {
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"START_PLAY" object:@[media]];
            complete(1, media, nil);
        }
        else {
            [DanmakuNetManager downThirdPartyDanmakuWithDanmaku:media.danmaku provider:media.danmakuSource completionHandler:^(NSDictionary *responseObj, DanDanPlayErrorModel *error) {
                self.currentIndex = index;
                media.danmakuDic = responseObj;
                if (index < _videos.count) {
                    _videos[index] = media;
//                    [[NSNotificationCenter defaultCenter] postNotificationName:@"START_PLAY" object:@[media]];
                    complete(1, media, error);
                }
            }];
        }
    }
}

- (void)downloadCurrentVideoWithProgress:(void (^)(id<VideoModelProtocol>model))downloadProgressBlock completionHandler:(void(^)(id<VideoModelProtocol>model, NSURL *downLoadURL, DanDanPlayErrorModel *error))complete {
    id<VideoModelProtocol>videoModel = self.currentVideoModel;
    if ([videoModel isKindOfClass:[StreamingVideoModel class]]) {
        StreamingVideoModel *vm = (StreamingVideoModel *)videoModel;
        //防止下载未完成更换地址
        NSInteger index = vm.URLIndex;
        StreamingVideoQuality quality = vm.quality;
        
        [VideoNetManager downloadVideoWithURL:vm.fileURL progress:^(NSProgress *downloadProgress) {
            vm.progress = downloadProgress.fractionCompleted;
            downloadProgressBlock(vm);
        } completionHandler:^(NSURL *downLoadURL, DanDanPlayErrorModel *error) {
            [vm setURL:downLoadURL quality:quality index:index];
            [self synchronizeVideoList];
            complete(vm, downLoadURL, error);
        }];
    }
}

#pragma mark - 懒加载
- (NSMutableArray *)userDanmaukuArr {
    if(_userDanmaukuArr == nil) {
        NSString *episodeId = self.currentVideoModel.episodeId;
        if (episodeId.length == 0) {
            _userDanmaukuArr = [UserDefaultManager userSentDanmaukuArrWithEpisodeId:episodeId];
        }
        
        if (!_userDanmaukuArr) {
            _userDanmaukuArr = [[NSMutableArray alloc] init];
        }
    }
    return _userDanmaukuArr;
}

@end
