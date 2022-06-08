//
//  QNLinkMicService.h
//  QNLiveKit
//
//  Created by 郭茜 on 2022/5/24.
//

#import <UIKit/UIKit.h>
#import "QNLiveService.h"
#import "QNMicLinker.h"
#import "QNLinkMicInvitationHandler.h"
#import "QNAudienceMicLinker.h"
#import "QNAnchorHostMicLinker.h"
#import "QNAnchorForwardMicLinker.h"

NS_ASSUME_NONNULL_BEGIN

//麦位监听
@protocol MicLinkerListener <NSObject>

/// 观众初始化进入直播间 回调给观众当前有哪些人在连麦
- (void)onInitLinkers:(NSArray <QNMicLinker *> *)linkers;

/// 有人上麦
- (void)onUserJoinLink:(QNMicLinker *)micLinker;

/// 有人下麦
- (void)onUserLeave:(QNMicLinker *)micLinker;

/// 有人麦克风变化
- (void)onUserMicrophoneStatusChange:(QNMicLinker *)micLinker;

/// 有人摄像头状态变化
- (void)onUserCameraStatusChange:(QNMicLinker *)micLinker;

/// 有人被踢
- (void)onUserBeKick:(QNMicLinker *)micLinker;

/// 有人扩展字段变化
- (void)onUserExtension:(QNMicLinker *)micLinker extension:(NSString *)extension;

@end

//连麦服务
@interface QNLinkMicService : QNLiveService

//初始化
- (instancetype)initWithLiveId:(NSString *)liveId;

@property (nonatomic, weak)id<MicLinkerListener> micLinkerListener;

//获取当前房间所有连麦用户
- (void)getAllLinker:(void (^)(NSArray <QNMicLinker *> *list))callBack;

//设置某人的连麦视频预览
- (void)setUserPreview:(QNVideoView *)preview uid:(NSString *)uid;

//上麦
- (void)onMic:(BOOL)mic camera:(BOOL)camera extends:(NSString *)extends callBack:(void (^)(NSString *rtcToken))callBack;

//下麦
- (void)downMicCallBack:(void (^)(QNMicLinker *mic))callBack;

//获取用户麦位状态
- (void)getMicStatus:(NSString *)uid type:(NSString *)type callBack:(void (^)(void))callBack;

//踢人
- (void)kickOutUser:(NSString *)uid callBack:(void (^)(QNMicLinker *mic))callBack;

//开关麦 type:mic/camera  flag:on/off
- (void)updateMicStatus:(NSString *)uid type:(NSString *)type flag:(BOOL)flag callBack:(void (^)(QNMicLinker *mic))callBack;

//更新扩展字段
- (void)updateExtension:(NSString *)extension callBack:(void (^)(QNMicLinker *mic))callBack;

//添加连麦监听
- (void)addMicLinkerListener:(id<MicLinkerListener>)listener;

//移除连麦监听
- (void)removeMicLinkerListener:(id<MicLinkerListener>)listener;

//获取连麦邀请处理器
- (QNLinkMicInvitationHandler *)getLinkMicInvitationHandler;

//观众向主播连麦
- (QNAudienceMicLinker *)getAudienceMicLinker;

//主播处理自己被连麦
- (QNAnchorHostMicLinker *)getAnchorHostMicLinker;

//主播向主播的跨房连麦
- (QNAnchorForwardMicLinker *)getAnchorForwardMicLinker;
@end

NS_ASSUME_NONNULL_END
