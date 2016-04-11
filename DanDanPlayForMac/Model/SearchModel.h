//
//  AnimesModel.h
//  DanWanPlayer
//
//  Created by JimHuang on 15/12/24.
//  Copyright © 2015年 JimHuang. All rights reserved.
//

#import "BaseModel.h"
@class EpisodesModel, SearchDataModel;

#pragma mark - 官方搜索模型
@interface SearchModel : BaseModel
@property (nonatomic, strong)NSArray<SearchDataModel*>* animes;
@end

@interface SearchDataModel : BaseModel
/**
 *  动画标题
 */
@property (nonatomic, strong)NSString* title;
/**
 *  动画类型
 1 - TV动画
 2 - TV动画特别放送
 3 - OVA
 4 - 剧场版
 5 - 音乐视频（MV）
 6 - 网络放送
 7 - 其他分类
 10 - 三次元电影
 20 - 三次元电视剧或国产动画
 99 - 未知（尚未分类）
 */
@property (nonatomic, strong)NSString* type;
/**
 *  分集
 */
@property (nonatomic, strong)NSArray<EpisodesModel*>* episodes;
@end

@interface EpisodesModel : BaseModel
/**
 *  分集标题
 */
@property (nonatomic, strong)NSString* title;
/**
 *  分集id
 */
@property (nonatomic, strong)NSString* ID;
@end


#pragma mark - bilibili搜索模型
@class BiliBiliSearchDataModel;
@interface BiliBiliSearchModel : BaseModel
@property (strong, nonatomic) NSArray <BiliBiliSearchDataModel *>*result;
@end

@interface BiliBiliSearchDataModel : BaseModel
//data分为两种 番剧和普通视频 用isBangumi属性区分
/**
 *  番剧id
 */
@property (strong, nonatomic) NSString *seasonID;
/**
 *  视频aid
 */
@property (strong, nonatomic) NSString *aid;
/**
 *  是否为番剧
 */
@property (assign, nonatomic, getter=isBangumi) BOOL bangumi;
/**
 *  番剧/视频 标题
 */
@property (strong, nonatomic) NSString *title;
/**
 *  番剧/视频 描述
 */
@property (strong, nonatomic) NSString *desc;
@end

#pragma mark - acfun搜索模型
@interface AcFunSearchModel : BaseModel
/**
 *  单集
 */
@property (strong, nonatomic) NSArray *list;
/**
 *  剧集
 */
@property (strong, nonatomic) NSArray *special;
@end


@interface AcFunSearchListModel : BaseModel
/**
 *  内容id
 */
@property (strong, nonatomic) NSString *contentId;
/**
 *  描述
 */
@property (strong, nonatomic) NSString *desc;
/**
 *  标题
 */
@property (strong, nonatomic) NSString *title;
/**
 *  是否为番剧
 */
@property (assign, nonatomic, getter=isBangumi) BOOL bangumi;
@end

@interface AcFunSearchSpecialModel : BaseModel
/**
 *  内容id
 */
@property (strong, nonatomic) NSString *contentId;
/**
 *  描述
 */
@property (strong, nonatomic) NSString *desc;
/**
 *  标题
 */
@property (strong, nonatomic) NSString *title;
/**
 *  封面
 */
@property (strong, nonatomic) NSURL *titleImg;
/**
 *  是否为番剧
 */
@property (assign, nonatomic, getter=isBangumi) BOOL bangumi;
@end