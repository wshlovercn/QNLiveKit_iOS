//
//  QNLiveRoomClient.m
//  QNLiveKit
//
//  Created by 郭茜 on 2022/5/24.
//

#import "QNLiveRoomClient.h"
#import "QNLiveNetworkUtil.h"
#import "QNLiveUser.h"
#import "QNLiveRoomInfo.h"

@interface QNLiveRoomClient ()<QNRoomLifeCycleListener>
@property (nonatomic, copy) NSString *liveId;
@end

@implementation QNLiveRoomClient

//获取房间所有用户
- (void)getUserList:(NSString *)roomId pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize callBack:(void (^)(NSArray<QNLiveUser *> * _Nonnull))callBack {
    
    NSString *action = [NSString stringWithFormat:@"client/live/room/user_list?live_id=%@&page_num=%ld&page_size=%ld",self.liveId,pageNumber,pageSize];
    [QNLiveNetworkUtil getRequestWithAction:action params:nil success:^(NSDictionary * _Nonnull responseData) {
        NSArray <QNLiveUser *> *list = [QNLiveUser mj_objectArrayWithKeyValuesArray:responseData[@"list"]];
        callBack(list);
        } failure:^(NSError * _Nonnull error) {
            callBack(nil);
        }];
}

//房间心跳
- (void)roomHeartBeart:(NSString *)roomId {
    
    NSString *action = [NSString stringWithFormat:@"client/live/room/heartbeat/%@",roomId];
    [QNLiveNetworkUtil getRequestWithAction:action params:nil success:^(NSDictionary * _Nonnull responseData) {
        
        } failure:^(NSError * _Nonnull error) {
            
        }];
}

//更新直播扩展信息
- (void)updateRoom:(NSString *)roomId extension:(NSString *)extension callBack:(void (^)(void))callBack{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"live_id"] = roomId;
    params[@"extends"] = extension;

    [QNLiveNetworkUtil putRequestWithAction:@"client/live/room/extends" params:params success:^(NSDictionary * _Nonnull responseData) {        
        
        if ([self.roomLifeCycleListener respondsToSelector:@selector(onRoomExtensions:)]) {
            [self.roomLifeCycleListener onRoomExtensions:extension];
        }
        callBack();
        
        } failure:^(NSError * _Nonnull error) {
            callBack();
        }];
}

//某个房间在线用户
- (void)getOnlineUser:(NSString *)roomId callBack:(void (^)(NSArray <QNLiveUser *> *list))callBack{
    NSString *action = [NSString stringWithFormat:@"client/live/room/user_list?live_id=%@&page_num=1&page_size=20",roomId];
    [QNLiveNetworkUtil getRequestWithAction:action params:nil success:^(NSDictionary * _Nonnull responseData) {
        NSArray <QNLiveUser *> *list = [QNLiveUser mj_objectArrayWithKeyValuesArray:responseData[@"list"]];
        callBack(list);
        } failure:^(NSError * _Nonnull error) {
            callBack(nil);
        }];
}

//使用用户ID搜索用户
- (void)searchUserByUserId:(NSString *)uid callBack:(void (^)(QNLiveUser *user))callBack{
    
    NSString *action = [NSString stringWithFormat:@"client/user/%@",uid];
    [QNLiveNetworkUtil getRequestWithAction:action params:nil success:^(NSDictionary * _Nonnull responseData) {
        QNLiveUser *user = [QNLiveUser mj_objectWithKeyValues:responseData];
        callBack(user);
        } failure:^(NSError * _Nonnull error) {
            callBack(nil);
        }];
}

//使用用户im uid 搜索用户
- (void)searchUserByIMUid:(NSString *)imUid callBack:(void (^)(QNLiveUser *user))callBack{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"im_user_ids"] = @[imUid].mj_keyValues;
    [QNLiveNetworkUtil getRequestWithAction:@"client/user/imusers" params:params success:^(NSDictionary * _Nonnull responseData) {
        QNLiveUser *user = [QNLiveUser mj_objectWithKeyValues:responseData];
        callBack(user);
        } failure:^(NSError * _Nonnull error) {
            callBack(nil);
        }];
}

- (QNLiveUser *)selfUser {
    QNLiveUser *user = [QNLiveUser new];
    user.user_id = QN_User_id;
    user.nick = QN_User_nickname;
    user.avatar = QN_User_avatar;
    user.im_userid = QN_IM_userId;
    user.im_username = QN_IM_userName;
    return user;
}
@end
