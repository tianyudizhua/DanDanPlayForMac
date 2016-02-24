//
//  Config.h
//  DanDanPlayForMac
//
//  Created by JimHuang on 16/1/28.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#ifndef Config_h
#define Config_h

//来源枚举
typedef NS_ENUM(NSInteger, JHDanMuSource){
    //官方
    JHDanMuSourceOfficial,
    //b站
    JHDanMuSourceBilibili,
    //a站
    JHDanMuSourceAcfun
};

#define kViewControllerWithId(ID) [[NSStoryboard storyboardWithName:@"Main" bundle: nil] instantiateControllerWithIdentifier: ID]

#define kNoMatchError [NSError errorWithDomain:@"nomatchdanmaku" code:200 userInfo: nil]

#endif /* Config_h */
