#import <Foundation/Foundation.h>
#import "KuiklyPlatformCompat.h"

NS_ASSUME_NONNULL_BEGIN

/// 对齐 Android renderAdapterProvider 的 iOS 侧统一适配器入口。
///
/// iOS render 核心目前只开放了桥接层已有的注册项，
/// 这里按当前能力提供统一注入入口，后续可继续扩展。
@protocol KuiklyRenderAdapterProvider <NSObject>

@optional
- (id<KuiklyRenderComponentExpandProtocol>)componentExpandHandler;
- (id<KuiklyLogProtocol>)logHandler;
- (APNGViewCreator)apngViewCreator;
- (PAGViewCreator)pagViewCreator;
- (id<KuiklyFontProtocol>)fontHandler;
- (id<KRCacheProtocol>)cacheHandler;

@end

NS_ASSUME_NONNULL_END
