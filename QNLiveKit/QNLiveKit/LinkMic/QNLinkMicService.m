//
//  QNLinkMicService.m
//  QNLiveKit
//
//  Created by 郭茜 on 2022/5/24.
//

#import "QNLinkMicService.h"
#import "QNLiveNetworkUtil.h"
#import "QNMicLinker.h"

@interface QNLinkMicService ()

@end

@implementation QNLinkMicService

- (instancetype)initWithLiveId:(NSString *)liveId {
    if (self = [super init]) {
        self.liveId = liveId;
    }
    return self;
}

//获取当前房间所有连麦用户
- (void)getAllLinker:(void (^)(NSArray <QNMicLinker *> *list))callBack {
    
    NSString *action = [NSString stringWithFormat:@"client/mic/room/list/%@",self.liveId];
    
    [QNLiveNetworkUtil getRequestWithAction:action params:@{} success:^(NSDictionary * _Nonnull responseData) {
        
        NSArray <QNMicLinker *> *list = [QNMicLinker mj_objectArrayWithKeyValuesArray:responseData];
        callBack(list);
        
        } failure:^(NSError * _Nonnull error) {
            callBack(nil);
        }];
}

//上麦
- (void)onMic:(BOOL)mic camera:(BOOL)camera extends:(nullable NSDictionary *)extends callBack:(nullable void (^)(NSString * _Nullable))callBack {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"live_id"] = self.liveId;
    params[@"mic"] = @(mic);
    params[@"camera"] = @(camera);
    params[@"extends"] = extends;
    
    [QNLiveNetworkUtil postRequestWithAction:@"client/mic/" params:params success:^(NSDictionary * _Nonnull responseData) {
        
//        QNMicLinker *mic = [QNMicLinker mj_objectWithKeyValues:responseData];
        callBack(responseData[@"rtc_token"]);
        
        } failure:^(NSError * _Nonnull error) {
            callBack(@"");
        }];
}

//下麦
- (void)downMicCallBack:(nullable void (^)(QNMicLinker *mic))callBack{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"live_id"] = self.liveId;
    params[@"mic"] = @(NO);
    params[@"camera"] = @(NO);

    [QNLiveNetworkUtil deleteRequestWithAction:@"client/mic" params:params success:^(NSDictionary * _Nonnull responseData) {
        
        QNMicLinker *mic = [QNMicLinker mj_objectWithKeyValues:responseData];
//        if ([self.micLinkerListener respondsToSelector:@selector(onUserLeave:)]) {
//            [self.micLinkerListener onUserLeave:mic];
//        }
        callBack(mic);
        
        } failure:^(NSError * _Nonnull error) {
            callBack(nil);
        }];
}

//获取用户麦位状态
- (void)getMicStatus:(NSString *)uid type:(NSString *)type callBack:(nullable void (^)(void))callBack{
    
}

//开关麦 type:mic/camera  flag:on/off
- (void)updateMicStatus:(NSString *)uid type:(NSString *)type flag:(BOOL)flag callBack:(nullable void (^)(QNMicLinker *mic))callBack{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"live_id"] = self.liveId;
    params[@"user_id"] = uid;
    params[@"type"] = type;
    params[@"flag"] = @(flag);

    [QNLiveNetworkUtil putRequestWithAction:@"client/mic/switch" params:params success:^(NSDictionary * _Nonnull responseData) {
        
        QNMicLinker *mic = [QNMicLinker mj_objectWithKeyValues:responseData];
        
//        if ([type isEqualToString:@"mic"]) {
//            if ([self.micLinkerListener respondsToSelector:@selector(onUserMicrophoneStatusChange:)]) {
//                [self.micLinkerListener onUserMicrophoneStatusChange:mic];
//            }
//        } else {
//            if ([self.micLinkerListener respondsToSelector:@selector(onUserCameraStatusChange:)]) {
//                [self.micLinkerListener onUserCameraStatusChange:mic];
//            }
//        }
        callBack(mic);
        
        } failure:^(NSError * _Nonnull error) {
            callBack(nil);
        }];
}

//踢人
- (void)kickOutUser:(NSString *)uid msg:(nullable NSString *)msg callBack:(nullable void (^)(QNMicLinker * _Nullable))callBack {

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"live_id"] = self.liveId;
    params[@"user_id"] = uid;
    
    [QNLiveNetworkUtil deleteRequestWithAction:@"mic/live" params:params success:^(NSDictionary * _Nonnull responseData) {
        
        QNLiveUser *user = [QNLiveUser new];
        user.user_id = uid;
        
        QNMicLinker *mic = [QNMicLinker new];
        mic.user = user;
        mic.userRoomId = self.liveId;
        
//        if ([self.micLinkerListener respondsToSelector:@selector(onUserBeKick:)]) {
//            [self.micLinkerListener onUserBeKick:mic];
//        }
        
        callBack(mic);
        } failure:^(NSError * _Nonnull error) {
            callBack(nil);
        }];
}

//更新扩展字段
- (void)updateExtension:(NSString *)extension callBack:(nullable void (^)(QNMicLinker *mic))callBack {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"live_id"] = self.liveId;
    params[@"user_id"] = QN_User_id;
    params[@"extends"] = extension;

    [QNLiveNetworkUtil putRequestWithAction:@"client/mic/extension" params:params success:^(NSDictionary * _Nonnull responseData) {
        
        QNMicLinker *mic = [QNMicLinker mj_objectWithKeyValues:responseData];
        
//        if ([self.micLinkerListener respondsToSelector:@selector(onUserExtension:extension:)]) {
//            [self.micLinkerListener onUserExtension:mic extension:extension];
//        }
        callBack(mic);
        
        } failure:^(NSError * _Nonnull error) {
            callBack(nil);
        }];
}


@end
