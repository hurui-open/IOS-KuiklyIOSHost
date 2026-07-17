#import "KuiklyRenderAdapterRegistry.h"

static id<KuiklyRenderAdapterProvider> gRenderAdapterProvider = nil;

@implementation KuiklyRenderAdapterRegistry

+ (void)installProvider:(id<KuiklyRenderAdapterProvider>)provider {
    gRenderAdapterProvider = provider;

    id<KuiklyRenderAdapterProvider> adapterProvider = gRenderAdapterProvider;
    if (!adapterProvider) {
        return;
    }

    if ([adapterProvider respondsToSelector:@selector(componentExpandHandler)]) {
        [KuiklyRenderBridge registerComponentExpandHandler:[adapterProvider componentExpandHandler]];
    }
    if ([adapterProvider respondsToSelector:@selector(logHandler)]) {
        [KuiklyRenderBridge registerLogHandler:[adapterProvider logHandler]];
    }
    if ([adapterProvider respondsToSelector:@selector(apngViewCreator)]) {
        [KuiklyRenderBridge registerAPNGViewCreator:[adapterProvider apngViewCreator]];
    }
    if ([adapterProvider respondsToSelector:@selector(pagViewCreator)]) {
        [KuiklyRenderBridge registerPAGViewCreator:[adapterProvider pagViewCreator]];
    }
    if ([adapterProvider respondsToSelector:@selector(fontHandler)]) {
        [KuiklyRenderBridge registerFontHandler:[adapterProvider fontHandler]];
    }
    if ([adapterProvider respondsToSelector:@selector(cacheHandler)]) {
        [KuiklyRenderBridge registerCacheHandler:[adapterProvider cacheHandler]];
    }
}

@end
