//
//  OpenStreamVideoViewModel.m
//  DanDanPlayForMac
//
//  Created by JimHuang on 16/3/5.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#import "OpenStreamVideoViewModel.h"
#import "DanMuNetManager.h"
#import "VideoInfoModel.h"
#import "StreamingVideoModel.h"
@interface OpenStreamVideoViewModel()
@property (strong, nonatomic) NSString *aid;
@property (strong, nonatomic) NSString *page;
@property (strong, nonatomic) NSString *danmakuSource;
@property (strong, nonatomic) NSArray <VideoInfoDataModel *>*models;
@end
@implementation OpenStreamVideoViewModel

- (NSInteger)numOfVideos{
    return self.models.count;
}
- (NSString *)videoNameForRow:(NSInteger)row{
    return [self modelForRow:row].title;
}
- (NSString *)danmakuForRow:(NSInteger)row{
    return [self modelForRow:row].danmaku;
}

- (void)getVideoURLAndDanmakuForRow:(NSInteger)row completionHandler:(void(^)(StreamingVideoModel *videoModel, NSError *error))complete{
    [self getVideoURLAndDanmakuForVideoName:[self videoNameForRow:row] danmaku:[self danmakuForRow:row] danmakuSource:self.danmakuSource completionHandler:complete];
}

- (void)getVideoURLAndDanmakuForVideoName:(NSString *)videoName danmaku:(NSString *)danmaku danmakuSource:(NSString *)danmakuSource completionHandler:(void(^)(StreamingVideoModel *videoModel, NSError *error))complete {
    if (!danmaku.length) {
        complete(nil, kObjNilError);
        return;
    }
    
    if (!videoName.length) videoName = @"";
    
    [VideoNetManager bilibiliVideoURLWithParameters:@{@"danmaku":danmaku} completionHandler:^(NSDictionary *videosDic, NSError *error) {
        [DanMuNetManager downThirdPartyDanMuWithParameters:@{@"provider":danmakuSource, @"danmaku":danmaku} completionHandler:^(id responseObj, NSError *error) {
            StreamingVideoModel *vm = [[StreamingVideoModel alloc] initWithFileURLs:videosDic fileName:videoName danmaku:danmaku danmakuSource:self.danmakuSource];
            vm.danmakuDic = responseObj;
            vm.quality = [UserDefaultManager defaultQuality];
            complete(vm, error);
        }];
    }];
}

- (void)refreshWithcompletionHandler:(void(^)(NSError *error))complete{
    [DanMuNetManager getBiliBiliDanMuWithParameters:@{@"aid":self.aid?self.aid:@"", @"page":self.page?self.page:@""} completionHandler:^(BiliBiliVideoInfoModel *responseObj, NSError *error) {
        self.models = responseObj.videos;
        complete(error);
    }];
}

- (instancetype)initWithAid:(NSString *)aid danmakuSource:(NSString *)danmakuSource{
    if (self = [super init]) {
        NSArray *arr = [aid componentsSeparatedByString:@" "];
        self.aid = [arr.firstObject substringFromIndex:2];
        self.page = arr.count > 1 ? arr.lastObject : nil;
        self.danmakuSource = danmakuSource;
    }
    return self;
}

#pragma mark - 私有方法
- (VideoInfoDataModel *)modelForRow:(NSInteger)row{
    return row < self.models.count ? self.models[row] : nil;
}
@end