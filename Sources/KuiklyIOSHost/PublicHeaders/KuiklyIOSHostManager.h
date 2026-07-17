#import <Foundation/Foundation.h>
#import "KuiklyHostRuntimeInstaller.h"
#import "KuiklyHostSupportConfiguration.h"
#import "KuiklyRenderAdapterProvider.h"
#import "KuiklyHostProviderRegistry.h"

NS_ASSUME_NONNULL_BEGIN

/// 对齐 Android KuiklyManager 的统一初始化入口。
@interface KuiklyIOSHostManager : NSObject

+ (void)initializeWithRuntimeInstaller:(KuiklyHostRuntimeInstaller *)runtimeInstaller
                  supportConfiguration:(KuiklyHostSupportConfiguration * _Nullable)supportConfiguration
               renderAdapterProvider:(id<KuiklyRenderAdapterProvider> _Nullable)renderAdapterProvider
                             providers:(NSArray<id<KuiklyHostProvider>> * _Nullable)providers;

@end

NS_ASSUME_NONNULL_END
