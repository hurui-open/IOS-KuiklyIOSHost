#ifdef __OBJC__
#import "KuiklyPlatformCompat.h"
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "KuiklyHostRuntimeInstaller.h"
#import "KuiklyHostSupportConfiguration.h"
#import "KuiklyRenderAdapterProvider.h"
#import "KuiklyHostProviderRegistry.h"
#import "KuiklyIOSHostManager.h"
#import "KuiklyRenderViewController.h"
#import "HRBridgeModule.h"

FOUNDATION_EXPORT double KuiklyIOSHostVersionNumber;
FOUNDATION_EXPORT const unsigned char KuiklyIOSHostVersionString[];
