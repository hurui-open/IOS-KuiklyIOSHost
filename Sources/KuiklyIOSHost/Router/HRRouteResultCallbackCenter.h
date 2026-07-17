#import <Foundation/Foundation.h>
#import "KuiklyPlatformCompat.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * iOS 路由结果回调中心。
 *
 * 职责：
 * - 维护 requestKey -> KuiklyRenderCallback 的映射
 * - 统一处理 Kuikly / 原生混合跳转时的“带结果返回”
 *
 * 对应 Android 的 `RouteResultCallbackCenter`。
 */
@interface HRRouteResultCallbackCenter : NSObject

/**
 * 注册结果回调。
 *
 * @param requestId 本次带结果跳转的 requestKey / callbackId。
 * @param callback 页面关闭时需要触发的回调。
 */
+ (void)registerCallbackWithId:(NSString *)requestId callback:(KuiklyRenderCallback)callback;

/**
 * 移除指定 requestKey 对应的回调。
 *
 * 一般用于：
 * - 页面提前销毁
 * - 主动取消等待结果
 */
+ (void)removeCallbackWithId:(NSString *)requestId;

/**
 * 取出并消费一次回调。
 *
 * 设计成 consume 而不是单纯 get 的原因：
 * - 正常一次返回只应该触发一次
 * - 避免同一 requestKey 被重复回调
 */
+ (KuiklyRenderCallback _Nullable)consumeCallbackWithId:(NSString *)requestId;

@end

NS_ASSUME_NONNULL_END
