#import <Foundation/Foundation.h>
#import "KuiklyRenderAdapterProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// iOS 侧渲染适配器注册中心。
///
/// 作用：
/// - 对齐 Android 的 RenderAdapterRegistry 形态
/// - 将宿主注入的适配器映射到 OpenKuiklyIOSRender 的桥接注册方法
@interface KuiklyRenderAdapterRegistry : NSObject

+ (void)installProvider:(id<KuiklyRenderAdapterProvider> _Nullable)provider;

@end

NS_ASSUME_NONNULL_END
