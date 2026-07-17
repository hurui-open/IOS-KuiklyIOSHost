#import "KuiklyHostProviderRegistry.h"
#import "KuiklyRenderViewController.h"
#import "KuiklyPlatformCompat.h"

static NSDictionary *hr_failure_result(NSString *message) {
    return @{
        @"code": @(-1),
        @"message": message ?: @""
    };
}

static id<KuiklyHostUiProvider> gUiProvider = nil;
static id<KuiklyHostScanProvider> gScanProvider = nil;
static id<KuiklyHostMediaProvider> gMediaProvider = nil;
static id<KuiklyHostNativeRouteProvider> gNativeRouteProvider = nil;
static id<KuiklyHostPageProvider> gPageProvider = nil;
static id<KuiklyHostProjectBridgeProvider> gProjectBridgeProvider = nil;

@implementation KuiklyDefaultUiProvider

- (void)toastWithContent:(NSString *)content hostViewController:(UIViewController *)hostViewController {
    __unused NSString *unusedContent = content;
    __unused UIViewController *unusedHostViewController = hostViewController;
}

- (void)showCenterToastWithArgs:(NSDictionary *)args hostViewController:(UIViewController *)hostViewController {
    __unused NSDictionary *unusedArgs = args;
    __unused UIViewController *unusedHostViewController = hostViewController;
}

- (void)showModalWithArgs:(NSDictionary *)args hostViewController:(UIViewController *)hostViewController callback:(KuiklyRenderCallback)callback {
    __unused NSDictionary *unusedArgs = args;
    __unused UIViewController *unusedHostViewController = hostViewController;
    if (callback) {
        callback(hr_failure_result(@"宿主未注入 UI 弹窗实现"));
    }
}

- (void)showResultModalWithArgs:(NSDictionary *)args hostViewController:(UIViewController *)hostViewController callback:(KuiklyRenderCallback)callback {
    __unused NSDictionary *unusedArgs = args;
    __unused UIViewController *unusedHostViewController = hostViewController;
    if (callback) {
        callback(hr_failure_result(@"宿主未注入 UI 结果弹窗实现"));
    }
}

- (void)showLoadingWithContent:(NSString *)content darkStyle:(BOOL)darkStyle hostViewController:(UIViewController *)hostViewController {
    __unused NSString *unusedContent = content;
    __unused BOOL unusedDarkStyle = darkStyle;
    __unused UIViewController *unusedHostViewController = hostViewController;
}

- (void)hideLoadingWithDarkStyle:(BOOL)darkStyle hostViewController:(UIViewController *)hostViewController {
    __unused BOOL unusedDarkStyle = darkStyle;
    __unused UIViewController *unusedHostViewController = hostViewController;
}

- (void)copyToPasteboardWithContent:(NSString *)content {
    if (content.length > 0) {
        [UIPasteboard generalPasteboard].string = content;
    }
}

- (NSString *)closeKeyboardForHostViewController:(UIViewController *)hostViewController {
#if TARGET_OS_OSX
    __unused UIViewController *unusedHostViewController = hostViewController;
    return nil;
#else
    [hostViewController.view endEditing:YES];
    return nil;
#endif
}

@end

@implementation KuiklyDefaultScanProvider

- (void)scanWithArgs:(NSDictionary *)args hostViewController:(UIViewController *)hostViewController callback:(KuiklyRenderCallback)callback {
    __unused NSDictionary *unusedArgs = args;
    __unused UIViewController *unusedHostViewController = hostViewController;
    if (callback) {
        callback(hr_failure_result(@"宿主未注入扫码实现"));
    }
}

@end

@implementation KuiklyDefaultMediaProvider

- (void)pickMediaWithArgs:(NSDictionary *)args hostViewController:(UIViewController *)hostViewController callback:(KuiklyRenderCallback)callback {
    __unused NSDictionary *unusedArgs = args;
    __unused UIViewController *unusedHostViewController = hostViewController;
    if (callback) {
        callback(hr_failure_result(@"宿主未注入媒体选择实现"));
    }
}

- (void)shareWithArgs:(NSDictionary *)args hostViewController:(UIViewController *)hostViewController callback:(KuiklyRenderCallback)callback {
    __unused NSDictionary *unusedArgs = args;
    __unused UIViewController *unusedHostViewController = hostViewController;
    if (callback) {
        callback(hr_failure_result(@"宿主未注入分享实现"));
    }
}

- (void)saveToAlbumWithArgs:(NSDictionary *)args hostViewController:(UIViewController *)hostViewController callback:(KuiklyRenderCallback)callback {
    __unused NSDictionary *unusedArgs = args;
    __unused UIViewController *unusedHostViewController = hostViewController;
    if (callback) {
        callback(hr_failure_result(@"宿主未注入相册保存实现"));
    }
}

- (void)uploadOssImageWithArgs:(NSDictionary *)args hostViewController:(UIViewController *)hostViewController callback:(KuiklyRenderCallback)callback {
    __unused NSDictionary *unusedArgs = args;
    __unused UIViewController *unusedHostViewController = hostViewController;
    if (callback) {
        callback(hr_failure_result(@"宿主未注入 OSS 上传实现"));
    }
}

@end

@implementation KuiklyDefaultNativeRouteProvider

- (BOOL)handleRouteWithName:(NSString *)name pageData:(NSDictionary *)pageData hostViewController:(UIViewController *)hostViewController onResult:(void (^)(NSDictionary *))onResult {
    __unused NSString *unusedName = name;
    __unused NSDictionary *unusedPageData = pageData;
    __unused UIViewController *unusedHostViewController = hostViewController;
    __unused void (^unusedOnResult)(NSDictionary *) = onResult;
    return NO;
}

- (UIViewController *)viewControllerForRouteName:(NSString *)name pageData:(NSDictionary *)pageData hostViewController:(UIViewController *)hostViewController onResult:(void (^)(NSDictionary *))onResult {
    __unused NSString *unusedName = name;
    __unused NSDictionary *unusedPageData = pageData;
    __unused UIViewController *unusedHostViewController = hostViewController;
    __unused void (^unusedOnResult)(NSDictionary *) = onResult;
    return nil;
}

@end

@implementation KuiklyDefaultPageProvider

- (void)openKuiklyPageWithName:(NSString *)pageName
                      pageData:(NSDictionary *)pageData
            hostViewController:(UIViewController *)hostViewController
                  closeCurrent:(BOOL)closeCurrent
                    clearStack:(BOOL)clearStack {
    __unused NSString *unusedPageName = pageName;
    __unused NSDictionary *unusedPageData = pageData;
    __unused UIViewController *unusedHostViewController = hostViewController;
    __unused BOOL unusedCloseCurrent = closeCurrent;
    __unused BOOL unusedClearStack = clearStack;
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"KuiklyPageProvider is not installed. Register a host page provider before opening Kuikly pages."
                                 userInfo:nil];
}

- (void)finishTop:(NSInteger)delta hostViewController:(UIViewController *)hostViewController {
    __unused NSInteger unusedDelta = delta;
    __unused UIViewController *unusedHostViewController = hostViewController;
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"KuiklyPageProvider is not installed. Register a host page provider before closing Kuikly pages."
                                 userInfo:nil];
}

@end

@implementation KuiklyNavigationPageProvider

- (void)openKuiklyPageWithName:(NSString *)pageName
                      pageData:(NSDictionary *)pageData
            hostViewController:(UIViewController *)hostViewController
                  closeCurrent:(BOOL)closeCurrent
                    clearStack:(BOOL)clearStack {
#if TARGET_OS_OSX
    __unused NSString *unusedPageName = pageName;
    __unused NSDictionary *unusedPageData = pageData;
    __unused UIViewController *unusedHostViewController = hostViewController;
    __unused BOOL unusedCloseCurrent = closeCurrent;
    __unused BOOL unusedClearStack = clearStack;
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"KuiklyNavigationPageProvider requires UIKit navigation support and is unavailable in macOS compatibility builds."
                                 userInfo:nil];
#else
    UINavigationController *navigationController = hostViewController.navigationController;
    if (!navigationController && [hostViewController isKindOfClass:[UINavigationController class]]) {
        navigationController = (UINavigationController *)hostViewController;
    }
    if (!navigationController) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"KuiklyNavigationPageProvider requires a UINavigationController host."
                                     userInfo:nil];
    }
    KuiklyRenderViewController *controller = [[KuiklyRenderViewController alloc] initWithPageName:pageName pageData:pageData ?: @{}];
    if (clearStack) {
        [navigationController setViewControllers:@[controller] animated:YES];
        return;
    }
    UIViewController *currentViewController = navigationController.topViewController;
    [navigationController pushViewController:controller animated:YES];
    if (closeCurrent && currentViewController) {
        NSMutableArray<UIViewController *> *viewControllers = [navigationController.viewControllers mutableCopy];
        [viewControllers removeObject:currentViewController];
        [navigationController setViewControllers:viewControllers animated:NO];
    }
#endif
}

- (void)finishTop:(NSInteger)delta hostViewController:(UIViewController *)hostViewController {
#if TARGET_OS_OSX
    __unused NSInteger unusedDelta = delta;
    __unused UIViewController *unusedHostViewController = hostViewController;
#else
    UIViewController *targetViewController = hostViewController;
    UINavigationController *navigationController = targetViewController.navigationController;
    if (!navigationController && [targetViewController isKindOfClass:[UINavigationController class]]) {
        navigationController = (UINavigationController *)targetViewController;
        targetViewController = navigationController.topViewController;
    }
    if (navigationController.viewControllers.count > 1) {
        NSInteger safeDelta = MAX(delta, 1);
        NSUInteger currentIndex = [navigationController.viewControllers indexOfObject:targetViewController];
        if (currentIndex == NSNotFound) {
            currentIndex = navigationController.viewControllers.count - 1;
        }
        NSInteger targetIndex = MAX((NSInteger)currentIndex - safeDelta, 0);
        [navigationController popToViewController:navigationController.viewControllers[(NSUInteger)targetIndex] animated:YES];
        return;
    }
    if (targetViewController.presentingViewController) {
        [targetViewController dismissViewControllerAnimated:YES completion:nil];
    }
#endif
}

@end

@implementation KuiklyDefaultProjectBridgeProvider

- (BOOL)handleMethod:(NSString *)method args:(NSDictionary *)args hostViewController:(UIViewController *)hostViewController callback:(KuiklyRenderCallback)callback {
    __unused NSString *unusedMethod = method;
    __unused NSDictionary *unusedArgs = args;
    __unused UIViewController *unusedHostViewController = hostViewController;
    __unused KuiklyRenderCallback unusedCallback = callback;
    return NO;
}

@end

@implementation KuiklyHostProviderRegistry

+ (void)initialize {
    if (self != [KuiklyHostProviderRegistry class]) {
        return;
    }
    gUiProvider = [[KuiklyDefaultUiProvider alloc] init];
    gScanProvider = [[KuiklyDefaultScanProvider alloc] init];
    gMediaProvider = [[KuiklyDefaultMediaProvider alloc] init];
    gNativeRouteProvider = [[KuiklyDefaultNativeRouteProvider alloc] init];
    gPageProvider = [[KuiklyDefaultPageProvider alloc] init];
    gProjectBridgeProvider = [[KuiklyDefaultProjectBridgeProvider alloc] init];
}

+ (id<KuiklyHostUiProvider>)uiProvider { return gUiProvider; }
+ (id<KuiklyHostScanProvider>)scanProvider { return gScanProvider; }
+ (id<KuiklyHostMediaProvider>)mediaProvider { return gMediaProvider; }
+ (id<KuiklyHostNativeRouteProvider>)nativeRouteProvider { return gNativeRouteProvider; }
+ (id<KuiklyHostPageProvider>)pageProvider { return gPageProvider; }
+ (id<KuiklyHostProjectBridgeProvider>)projectBridgeProvider { return gProjectBridgeProvider; }

+ (void)installProviders:(NSArray<id<KuiklyHostProvider>> *)providers {
    for (id<KuiklyHostProvider> provider in providers) {
        if ([provider conformsToProtocol:@protocol(KuiklyHostUiProvider)]) {
            gUiProvider = (id<KuiklyHostUiProvider>)provider;
        }
        if ([provider conformsToProtocol:@protocol(KuiklyHostScanProvider)]) {
            gScanProvider = (id<KuiklyHostScanProvider>)provider;
        }
        if ([provider conformsToProtocol:@protocol(KuiklyHostMediaProvider)]) {
            gMediaProvider = (id<KuiklyHostMediaProvider>)provider;
        }
        if ([provider conformsToProtocol:@protocol(KuiklyHostNativeRouteProvider)]) {
            gNativeRouteProvider = (id<KuiklyHostNativeRouteProvider>)provider;
        }
        if ([provider conformsToProtocol:@protocol(KuiklyHostPageProvider)]) {
            gPageProvider = (id<KuiklyHostPageProvider>)provider;
        }
        if ([provider conformsToProtocol:@protocol(KuiklyHostProjectBridgeProvider)]) {
            gProjectBridgeProvider = (id<KuiklyHostProjectBridgeProvider>)provider;
        }
    }
}

@end
