#import <Foundation/Foundation.h>
#import "KuiklyPlatformCompat.h"

NS_ASSUME_NONNULL_BEGIN

/// 保持和历史桥接模块名一致，确保 Kuikly 侧 method 调用无感切换。
@interface HRBridgeModule : KRBaseModule

+ (void)registerRouteResultCallbackWithId:(NSString *)requestId
                                 callback:(KuiklyRenderCallback)callback;
+ (void)removeRouteResultCallbackWithId:(NSString *)requestId;

@end

NS_ASSUME_NONNULL_END
