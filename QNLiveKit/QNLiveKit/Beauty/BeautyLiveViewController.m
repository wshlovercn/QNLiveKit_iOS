//
//  BeautyLiveViewController.m
//  QNLiveKit
//
//  Created by 郭茜 on 2022/6/30.
//

#import "BeautyLiveViewController.h"
#import "QNLivePushClient.h"
#import "QNLiveRoomClient.h"
#import "RoomHostView.h"
#import "OnlineUserView.h"
#import "BottomMenuView.h"
#import "QLinkMicService.h"
#import "QNChatRoomService.h"
#import "LiveChatRoom.h"
#import "QNLiveRoomInfo.h"
#import "QNMergeOption.h"
#import "QAlertView.h"
#import "QInvitationModel.h"
#import "QRenderView.h"
#import "QLive.h"
#import "QNLiveUser.h"
#import "QNPKInvitationListController.h"
#import "QPKService.h"
#import "LinkInvitation.h"
#import <QNRTCKit/QNRTCKit.h>
#import "FDanmakuView.h"
#import "FDanmakuModel.h"
#import "QIMModel.h"
#import "PubChatModel.h"
#import "QToastView.h"
#import <QNIMSDK/QNIMSDK.h>
#import "ShopSellListController.h"
#import "GoodsModel.h"
#import "QLiveNetworkUtil.h"
#import "ExplainingGoodView.h"
#import "QAlertView.h"
#import "UIViewController+QViewController.h"
#import "QStatisticalService.h"
#import "LiveBottomMoreView.h"
#import "QNGiftMessagePannel.h"
#import "QNLiveStatisticView.h"

@interface BeautyLiveViewController ()<QNPushClientListener,QNRoomLifeCycleListener,QNPushClientListener,QNChatRoomServiceListener,FDanmakuViewProtocol,LiveChatRoomViewDelegate,MicLinkerListener,PKServiceListener,QNLocalVideoTrackDelegate>

@property (nonatomic, strong) QNLiveRoomInfo *selectPkRoomInfo;
@property (nonatomic, strong) QNPKSession *pkSession;//正在进行的pk
@property (nonatomic, strong) QNLiveUser *pk_other_user;//pk对象
@property (nonatomic, strong) ImageButtonView *pkSlot;
@property (nonatomic, strong) LiveBottomMoreView *moreView;
@property (nonatomic, strong) QNLiveStatisticView *statisticView;


@end

@implementation BeautyLiveViewController

+ (void)initialize {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"SENSEME" ofType:@"lic"];
    NSData* license = [NSData dataWithContentsOfFile:path];
    [[STDefaultSetting sharedInstace] checkActiveCodeWithData:license];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [[QLive createPusherClient] setVideoFrameListener:self];
    [[QLive createPusherClient] enableCamera:nil renderView:self.preview];
    [QLive createPusherClient].pushClientListener = self;
    
    self.linkService.micLinkerListener = self;
    self.pkService.delegate = self;
    self.danmakuView.delegate = self;
    self.chatRoomView.delegate = self;
    [self.chatService addChatServiceListener:self];
    [[QLive createPusherClient] startLive:self.roomInfo.live_id callBack:^(QNLiveRoomInfo * _Nonnull roomInfo) {
        self.roomInfo = roomInfo;
        [self updateRoomInfo];
    }];
        
    [self.view addSubview:self.roomHostView];
    [self.view addSubview:self.onlineUserView];
    [self.view addSubview:self.pubchatView];
    [self.view addSubview:self.bottomMenuView];
    [self.view addSubview:self.closeButton];
    [self.view addSubview:self.giftMessagePannel];
    [self.view addSubview:self.statisticView];
    [self setupSenseAR];
    [self setupBottomMenuView];
    
    __weak typeof(self)weakSelf = self;
    [self.chatService sendWelComeMsg:^(QNIMMessageObject * _Nonnull msg) {
        [weakSelf.chatRoomView showMessage:msg];
    }];
    
}

- (void)updateRoomInfo {
    [[QLive createPusherClient] roomHeartBeart:self.roomInfo.live_id];
    [[QLive getRooms] getRoomInfo:self.roomInfo.live_id callBack:^(QNLiveRoomInfo * _Nonnull roomInfo) {
        self.roomInfo = roomInfo;
        [self.roomHostView updateWith:roomInfo];
        [self.onlineUserView updateWith:roomInfo];
        [self.statisticView updateWith:roomInfo];
    }];
    __weak typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf updateRoomInfo];
    });
}

#pragma mark ---------QNPushClientListener
//房间连接状态
- (void)onConnectionRoomStateChanged:(QNConnectionState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (state == QNConnectionStateConnected) {

        } else if (state == QNConnectionStateDisconnected) {
            [self.chatService sendLeaveMsg];
//            [[QLive createPusherClient] closeRoom];
//            [QToastView showToast:@"您已离线"];
            [self dismissViewControllerAnimated:YES completion:nil];
            
        }
    });
}

- (void)onUserLeaveRTC:(NSString *)userID {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.pk_other_user) {
            [self stopPK];
        }
        
        if (self.remoteView.superview && [self.remoteView.userId isEqualToString:userID]) {
            self.remoteView.frame = CGRectZero;
        }
    });
}

- (void)didStartLiveStreaming:(NSString *)streamID {
    //更新自己的混流布局
    if (self.pk_other_user) {
        CameraMergeOption *option = [CameraMergeOption new];
        option.frame = CGRectMake(0, 0, 720/2, 419);
        option.mZ = 0;
        [[[QLive createPusherClient] getMixStreamManager] updateUserVideoMixStreamingWithTrackId:[QLive createPusherClient].localVideoTrack.trackID option:option];
    }
}

- (void)onUserPublishTracks:(NSArray<QNRemoteTrack *> *)tracks ofUserID:(NSString *)userID {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        for (QNRemoteTrack *track in tracks) {
            if (track.kind == QNTrackKindVideo) {
                QNRemoteVideoTrack *videoTrack = (QNRemoteVideoTrack *)track;
                self.remoteView.frame = CGRectMake(SCREEN_W - 120, 120, 100, 100);
                self.remoteView.userId = userID;
                self.remoteView.trackId = videoTrack.trackID;
                self.remoteView.layer.cornerRadius = 50;
                self.remoteView.clipsToBounds = YES;

                [videoTrack play:self.remoteView];
                
                if (self.pk_other_user) {
                    
                    self.preview.frame = CGRectMake(0, 130, SCREEN_W/2, SCREEN_W/1.5);
                    self.remoteView.frame = CGRectMake(SCREEN_W/2, 130, SCREEN_W/2, SCREEN_W/1.5);
                    self.remoteView.layer.cornerRadius = 0;
                              
                    [[[QLive createPusherClient] getMixStreamManager] updateMixStreamSize:CGSizeMake(720, 419)];
                    CameraMergeOption *userOption = [CameraMergeOption new];
                    userOption.frame = CGRectMake(720/2, 0, 720/2, 419);
                    userOption.mZ = 0;
                    [[[QLive createPusherClient] getMixStreamManager] updateUserVideoMixStreamingWithTrackId:videoTrack.trackID option:userOption];
                    
                } else {
                    
                    [[[QLive createPusherClient] getMixStreamManager] updateMixStreamSize:CGSizeMake(720, 1280)];
                    CameraMergeOption *userOption = [CameraMergeOption new];
                    userOption.frame = CGRectMake(720-184-30, 200, 184, 184);
                    userOption.mZ = 1;
                    [[[QLive createPusherClient] getMixStreamManager] updateUserVideoMixStreamingWithTrackId:videoTrack.trackID option:userOption];
                }
            }
        }
    });
}

- (void)localVideoTrack:(QNLocalVideoTrack *)localVideoTrack didGetPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
    QNCameraVideoTrack *track = (QNCameraVideoTrack *)localVideoTrack;
    
    static st_mobile_human_action_t result;
    static st_mobile_animal_face_t animalResult;
    QNAllResult res;
    memset(&res, 0, sizeof(res));
    res.animal_result = &animalResult;
    res.humanResult = &result;
    
    [self updateFirstEnterUI];
    
    QNDetectConfig detectConfig;
    memset(&detectConfig, 0, sizeof(QNDetectConfig));
    detectConfig.humanConfig = [self.effectManager getEffectDetectConfig];
    detectConfig.animalConfig = [self.effectManager getEffectAnimalDetectConfig];
    
    [self.detector detect:pixelBuffer cameraOrientation:track.videoOrientation detectConfig:detectConfig allResult:&res];
    [self.effectManager processBuffer:pixelBuffer cameraOrientation:track.videoOrientation detectResult:&res];
}

#pragma mark ---------QNChatRoomServiceListener

- (void)onUserJoin:(QNLiveUser *)user message:(nonnull QNIMMessageObject *)message {
    [self.chatRoomView showMessage:message];
}

- (void)onUserLeave:(QNLiveUser *)user message:(QNIMMessageObject *)message {
    [self.chatRoomView showMessage:message];
}

//收到弹幕
- (void)onReceivedDamaku:(PubChatModel *)msg {
    FDanmakuModel *model = [[FDanmakuModel alloc]init];
    model.beginTime = 1;
    model.liveTime = 5;
    model.content = msg.content;
    model.sendNick = msg.sendUser.nick;
    model.sendAvatar = msg.sendUser.avatar;
    
    [self.danmakuView.modelsArr addObject:model];
}

// 收到喜欢消息
- (void)onReceivedLikeMsg:(QNIMMessageObject *)msg {
    
}

// 收到礼物消息
- (void)onreceivedGiftMsg:(QNIMMessageObject *)msg {
    [self.chatRoomView showMessage:msg];
    [self.giftMessagePannel showGiftMessage:msg];
}

-(NSTimeInterval)currentTime {
    static double time = 0;
    time += 0.1 ;
    return time;
}

- (UIView *)danmakuViewWithModel:(FDanmakuModel*)model {
    
    UILabel *label = [UILabel new];
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = [UIColor whiteColor];
    label.text = model.content;
    [label sizeToFit];
    return label;
}

- (void)didSendMessageModel:(QNIMMessageObject *)model {
    QIMModel *imModel = [QIMModel mj_objectWithKeyValues:model.content.mj_keyValues];
    PubChatModel *chatModel = [PubChatModel mj_objectWithKeyValues:imModel.data];
    if ([chatModel.action isEqualToString:living_danmu]) {
        FDanmakuModel *danmuModel = [[FDanmakuModel alloc]init];
        danmuModel.beginTime = 1;
        danmuModel.liveTime = 5;
        danmuModel.content = chatModel.content;
        [self.danmakuView.modelsArr addObject:danmuModel];
    }
    [self.statisticalService uploadComments];
}

//收到下麦消息
- (void)onUserLeaveLink:(QNMicLinker *)linker {
    if (self.remoteView.superview) {
        [self.remoteView removeFromSuperview];
    }
}

//有人被踢消息
- (void)onUserBeKick:(LinkOptionModel *)micLinker {
    if ([self.remoteView.userId isEqualToString:micLinker.uid]) {
        self.remoteView.frame = CGRectZero;
        self.preview.frame = self.view.frame;
    }
}

//收到公聊消息
- (void)onReceivedPuChatMsg:(PubChatModel *)msg message:(QNIMMessageObject *)message {
    [self.chatRoomView showMessage:message];
}

//收到开关视频消息
- (void)onUserCameraStatusChange:(NSString *)uid mute:(BOOL)mute{
    self.remoteView.hidden = mute;
}

//收到开关音频消息
- (void)onUserMicrophoneStatusChange:(NSString *)uid mute:(BOOL)mute {
    
}

//接受到连麦邀请
- (void)onReceiveLinkInvitation:(QInvitationModel *)model {
    NSString *title = [model.invitation.msg.initiator.nick stringByAppendingString:@"申请加入连麦，是否同意？"];
    [QAlertView showBaseAlertWithTitle:title content:@"" cancelHandler:^(UIAlertAction * _Nonnull action) {
        
    } confirmHandler:^(UIAlertAction * _Nonnull action) {
        [self.linkService AcceptLink:model];
    }];
}

//接收到pk邀请
- (void)onReceivePKInvitation:(QInvitationModel *)model {
    NSString *title = [model.invitation.msg.initiator.nick stringByAppendingString:@"邀请您PK，是否同意？"];
    [QAlertView showBaseAlertWithTitle:title content:@"" cancelHandler:^(UIAlertAction * _Nonnull action) {
        
    } confirmHandler:^(UIAlertAction * _Nonnull action) {
        [self.pkService AcceptPK:model];
        self.pk_other_user = model.invitation.msg.initiator;
    }];
}

//收到同意pk邀请
- (void)onReceivePKInvitationAccept:(QNPKSession *)model {
    [QToastView showToast:@"对方主播同意pk"];
    self.pkSlot.selected = YES;
    self.pk_other_user = model.receiver;
}

//收到开始pk信令
- (void)onReceiveStartPKSession:(QNPKSession *)pkSession {
    [QToastView showToast:@"pk马上开始"];
    self.pk_other_user = pkSession.initiator;
    self.pkSlot.selected = YES;
}

//收到结束pk消息
- (void)onReceiveStopPKSession:(QNPKSession *)pkSession {
    [self stopPK];
}

//主动结束pk
- (void)stopPK {
    self.pkSlot.selected = NO;
    self.preview.frame = self.view.frame;
    [self.renderBackgroundView bringSubviewToFront:self.preview];
    self.pk_other_user = nil;
    [self.pkService stopPK:nil];
}

#pragma mark - SubViews
- (RoomHostView *)roomHostView {
    if (!_roomHostView) {
        _roomHostView = [[RoomHostView alloc]initWithFrame:CGRectMake(8, 60, 135, 40)];
        [_roomHostView updateWith:self.roomInfo];;
        _roomHostView.clickBlock = ^(BOOL selected){
            NSLog(@"点击了房主头像");
        };
    }
    return _roomHostView;
}

- (OnlineUserView *)onlineUserView {
    if (!_onlineUserView) {
        _onlineUserView = [[OnlineUserView alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 190, 60, 150, 60)];
        [_onlineUserView updateWith:self.roomInfo];
        _onlineUserView.clickBlock = ^(BOOL selected){
            NSLog(@"点击了在线人数");
        };
    }
    return _onlineUserView;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_W - 40, 70, 20, 20)];
        [_closeButton setImage:[UIImage imageNamed:@"icon_quit"] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeViewController) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (ImageButtonView *)pubchatView {
    if (!_pubchatView) {
        _pubchatView = [[ImageButtonView alloc]initWithFrame:CGRectMake(15, SCREEN_H - 52.5, 170, 30)];
        _pubchatView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
        _pubchatView.layer.cornerRadius = 15;
        _pubchatView.clipsToBounds = YES;
        
        UIImageView *imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"pub_chat"]];
        imageView.frame = CGRectMake(10, 7, 16, 16);
        [_pubchatView addSubview:imageView];
        
        __weak typeof(self)weakSelf = self;
        _pubchatView.clickBlock = ^(BOOL selected){
            [weakSelf.chatRoomView commentBtnPressedWithPubchat:YES];
        };
        
    }
    return _pubchatView;
}

- (BottomMenuView *)bottomMenuView {
    if (!_bottomMenuView) {
        _bottomMenuView = [[BottomMenuView alloc]initWithFrame:CGRectMake(200, SCREEN_H - 60, SCREEN_W - 200, 45)];
    }
    return _bottomMenuView;
}

- (void)setupBottomMenuView {
    
    NSMutableArray *slotList = [NSMutableArray array];
    __weak typeof(self)weakSelf = self;
    
    //弹幕
    ImageButtonView *message = [[ImageButtonView alloc]initWithFrame:CGRectZero];
    [message bundleNormalImage:@"icon_danmu" selectImage:@"icon_danmu"];
    message.clickBlock = ^(BOOL selected){
        [weakSelf.chatRoomView commentBtnPressedWithPubchat:NO];
    };
    [slotList addObject:message];
    
    
    //pk
    ImageButtonView *pk = [[ImageButtonView alloc]initWithFrame:CGRectZero];
    [pk bundleNormalImage:@"pk" selectImage:@"end_pk"];
    pk.clickBlock = ^(BOOL selected){
        if (selected) {
            [[QLive getRooms] listRoom:1 pageSize:20 callBack:^(NSArray<QNLiveRoomInfo *> * _Nonnull list) {
                [weakSelf popInvitationPKView:list];
            }];
        } else {
            [weakSelf stopPK];
        }
    };
    [slotList addObject:pk];
    self.pkSlot = pk;
    
    //购物车
    ImageButtonView *shopping = [[ImageButtonView alloc]initWithFrame:CGRectZero];
    [shopping bundleNormalImage:@"shopping" selectImage:@"shopping"];
    shopping.clickBlock = ^(BOOL selected){
        [weakSelf popGoodListView];
    };
    [slotList addObject:shopping];
    
    //更多
    ImageButtonView *more = [[ImageButtonView alloc]initWithFrame:CGRectZero];
    [more bundleNormalImage:@"icon_more" selectImage:@"icon_more"];
    more.clickBlock = ^(BOOL selected) {
        [weakSelf popMoreView];
    };
    [slotList addObject:more];
    
    [self.bottomMenuView updateWithSlotList:slotList.copy];
    
}

- (void)popMoreView {
    __weak typeof(self)weakSelf = self;
    self.moreView = [[LiveBottomMoreView alloc]initWithFrame:CGRectMake(0, SCREEN_H - 200, SCREEN_W, 200) beauty:YES];
    
    self.moreView.cameraChangeBlock = ^{
        [[QNLivePushClient createPushClient] switchCamera];
    };
    self.moreView.microphoneBlock = ^(BOOL mute) {
        [[QNLivePushClient createPushClient] muteMicrophone:mute];
    };
    self.moreView.cameraMirrorBlock = ^(BOOL mute) {
        [QNLivePushClient createPushClient].localVideoTrack.previewMirrorFrontFacing = !mute;
    };
    self.moreView.beautyBlock = ^{
        [weakSelf clickBottomViewButton:weakSelf.beautyBtn];
    };
    self.moreView.effectsBlock = ^ {
        [weakSelf clickBottomViewButton:weakSelf.specialEffectsBtn];
    };
    [self.view addSubview:self.moreView];
}

- (void)popGoodListView {
    
    ShopSellListController *vc = [[ShopSellListController alloc] initWithLiveInfo:self.roomInfo];
    vc.view.frame = CGRectMake(0, 0, SCREEN_W, SCREEN_H);
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self addChildViewController:vc];
    [self.view addSubview:vc.view];
    
}

- (void)closeViewController {
    [QAlertView showThreeActionAlertWithTitle:@"确定关闭直播间吗？" content:@"关闭后无法再进入该直播间" firstAction:@"结束直播" firstHandler:^(UIAlertAction * _Nonnull action) {

        if (self.pk_other_user) {
            [self stopPK];
        }
        [self.chatService sendLeaveMsg];
        [[QLive createPusherClient] closeRoom];
        [self dismissViewControllerWithCount:2 animated:YES];
    } secondAction:@"仅暂停直播" secondHandler:^(UIAlertAction * _Nonnull action) {
        
        if (self.pk_other_user) {
            [self stopPK];
        }
        
        [[QLive createPusherClient] leaveRoom];
        [self dismissViewControllerWithCount:2 animated:YES];
    } threeHandler:^(UIAlertAction * _Nonnull action) {
        
    }];
}

//邀请面板
- (void)popInvitationPKView:(NSArray<QNLiveRoomInfo *> *)list {
    
    NSArray<QNLiveRoomInfo *> *resultList = [self filterListWithList:list];
    QNPKInvitationListController *vc = [[QNPKInvitationListController alloc] initWithList:resultList];
    __weak typeof(self)weakSelf = self;
    vc.invitationClickedBlock = ^(QNLiveRoomInfo * _Nonnull itemModel) {
        
        [weakSelf.pkService applyPK:itemModel.live_id receiveUser:itemModel.anchor_info];
        weakSelf.selectPkRoomInfo = itemModel;
        [QToastView showToast:@"pk邀请已发送"];
    };
    [self addChildViewController:vc];
    [self.view addSubview:vc.view];
    
    [vc.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(240);
        make.bottom.equalTo(self.view);
    }];
}

//筛除掉自己的直播间
- (NSArray<QNLiveRoomInfo *> *)filterListWithList:(NSArray<QNLiveRoomInfo *> *)list{
    NSMutableArray *resultList = [NSMutableArray array];
    for (QNLiveRoomInfo *room in list) {
        if (![room.anchor_info.user_id isEqualToString:LIVE_User_id]) {
            [resultList addObject:room];
        }
    }
    return resultList;
}

- (QStatisticalService *)statisticalService {
    if (!_statisticalService) {
        _statisticalService = [[QStatisticalService alloc]init];
        _statisticalService.roomInfo = self.roomInfo;
    }
    return _statisticalService;
}

- (QNGiftMessagePannel *)giftMessagePannel {
    if (!_giftMessagePannel) {
        _giftMessagePannel = [[QNGiftMessagePannel alloc] initWithFrame:CGRectMake(8, SCREEN_H - 315 - 150, 170, 150)];
    }
    return _giftMessagePannel;
}

- (QNLiveStatisticView *)statisticView {
    if (!_statisticView) {
        _statisticView = [[QNLiveStatisticView alloc] initWithFrame:CGRectMake(8, 108, 130, 16)];
        _statisticView.roomInfo = self.roomInfo;
    }
    return _statisticView;
}

@end
