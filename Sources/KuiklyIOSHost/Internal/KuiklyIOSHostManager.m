#import "KuiklyIOSHostManager.h"
#import "KuiklyRenderAdapterRegistry.h"

double KuiklyIOSHostVersionNumber = 1.0;
const unsigned char KuiklyIOSHostVersionString[] = "1.0.2";

@implementation KuiklyIOSHostManager

+ (void)initializeWithRuntimeInstaller:(KuiklyHostRuntimeInstaller *)runtimeInstaller
                  supportConfiguration:(KuiklyHostSupportConfiguration *)supportConfiguration
               renderAdapterProvider:(id<KuiklyRenderAdapterProvider>)renderAdapterProvider
                             providers:(NSArray<id<KuiklyHostProvider>> *)providers {
    [KuiklyHostSupportConfiguration installConfiguration:supportConfiguration ?: [KuiklyHostSupportConfiguration defaultConfiguration]];
    [KuiklyRenderAdapterRegistry installProvider:renderAdapterProvider];
    if (providers.count > 0) {
        [KuiklyHostProviderRegistry installProviders:providers];
    }
    if (runtimeInstaller.installBlock) {
        runtimeInstaller.installBlock();
    }
}

@end
