#import "HRBridgeModule.h"

#import <CoreImage/CoreImage.h>
#import <Photos/Photos.h>
#import <SDWebImage/SDWebImageManager.h>
#import "KuiklyPlatformCompat.h"

#import "KuiklyHostProviderRegistry.h"
#import "KuiklyHostSupportConfiguration.h"
#import "KuiklyRenderViewController.h"
#import "HROffscreenRenderController.h"
#import "HRRoutePageParser.h"
#import "HRRouteResultCallbackCenter.h"

static NSString *const HRRequestKeyParam = @"__lc_request_key";
static NSString *const HRResultParam = @"result";

static NSDictionary *hr_bridge_result(NSInteger code, NSString *message) {
    return @{
        @"code": @(code),
        @"message": message ?: @""
    };
}

static UIViewController *hr_findViewControllerFromView(UIView *view) {
    UIResponder *responder = view;
    while (responder) {
        responder = responder.nextResponder;
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

static Class hr_swiftClassNamed(NSString *className) {
    if (className.length == 0) {
        return Nil;
    }
    Class cls = NSClassFromString(className);
    if (cls) {
        return cls;
    }
    NSString *moduleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (moduleName.length == 0) {
        moduleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleExecutableKey];
    }
    if (moduleName.length == 0) {
        return Nil;
    }
    NSString *namespacedName = [NSString stringWithFormat:@"%@.%@", moduleName, className];
    return NSClassFromString(namespacedName);
}

static void hr_requestPhotoLibraryAddAuthorization(void (^completion)(BOOL granted, NSString *message)) {
    if (!completion) {
        return;
    }
    Class permissionBridgeClass = hr_swiftClassNamed(@"LCSPhotoPermissionBridge");
    SEL statusSelector = NSSelectorFromString(@"authorizationStatus");
    SEL requestSelector = NSSelectorFromString(@"requestAuthorization:");
    if (!permissionBridgeClass || ![permissionBridgeClass respondsToSelector:statusSelector] || ![permissionBridgeClass respondsToSelector:requestSelector]) {
        completion(NO, @"当前无相册权限");
        return;
    }
    typedef PHAuthorizationStatus (*HRPhotoAuthorizationStatusIMP)(id, SEL);
    HRPhotoAuthorizationStatusIMP statusImp = (HRPhotoAuthorizationStatusIMP)[permissionBridgeClass methodForSelector:statusSelector];
    PHAuthorizationStatus status = statusImp(permissionBridgeClass, statusSelector);
    if (status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited) {
        completion(YES, nil);
        return;
    }
    if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
        completion(NO, @"当前无相册权限");
        return;
    }
    typedef void (*HRPhotoRequestAuthorizationIMP)(id, SEL, void (^)(PHAuthorizationStatus));
    HRPhotoRequestAuthorizationIMP requestImp = (HRPhotoRequestAuthorizationIMP)[permissionBridgeClass methodForSelector:requestSelector];
    requestImp(permissionBridgeClass, requestSelector, ^(PHAuthorizationStatus newStatus) {
        if (newStatus == PHAuthorizationStatusAuthorized || newStatus == PHAuthorizationStatusLimited) {
            completion(YES, nil);
        } else {
            completion(NO, @"当前无相册权限");
        }
    });
}

static void hr_saveImageToPhotoLibrary(UIImage *image, void (^completion)(BOOL success, NSString *message)) {
    if (!completion) {
        return;
    }
    if (!image) {
        completion(NO, @"图片为空");
        return;
    }
    hr_requestPhotoLibraryAddAuthorization(^(BOOL granted, NSString *message) {
        if (!granted) {
            completion(NO, message ?: @"当前无相册权限");
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        completion(YES, nil);
                    } else {
                        completion(NO, error.localizedDescription ?: @"保存失败");
                    }
                });
            }];
        });
    });
}

static NSString *hr_qrCodeDirectoryPath(void) {
    NSArray<NSURL *> *cacheURLs = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory
                                                                         inDomains:NSUserDomainMask];
    NSURL *cacheURL = cacheURLs.firstObject;
    if (!cacheURL) {
        return NSTemporaryDirectory();
    }
    NSURL *dirURL = [cacheURL URLByAppendingPathComponent:@"einvoice_qrcode" isDirectory:YES];
    return dirURL.path;
}

static UIImage *hr_imageByApplyingMargin(UIImage *image, NSInteger margin) {
    if (!image || margin <= 0) {
        return image;
    }
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    CGFloat innerWidth = MAX(width - margin * 2, 1);
    CGFloat innerHeight = MAX(height - margin * 2, 1);
#if TARGET_OS_OSX
    KRUIGraphicsImageRendererFormat *format = [KRUIGraphicsImageRendererFormat defaultFormat];
    KRUIGraphicsImageRenderer *renderer = [[KRUIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(width, height) format:format];
    UIImage *result = [renderer imageWithActions:^(KRUIGraphicsImageRendererContext * _Nonnull rendererContext) {
        [image drawInRect:CGRectMake(margin, margin, innerWidth, innerHeight)];
    }];
    return result ?: image;
#else
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, image.scale > 0 ? image.scale : 1.0);
    [image drawInRect:CGRectMake(margin, margin, innerWidth, innerHeight)];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result ?: image;
#endif
}

static NSDictionary *hr_qrCodeSuccessResult(NSString *path, NSString *fileName, NSInteger size) {
    NSString *uri = [@"file://" stringByAppendingString:path ?: @""];
    return @{
        @"success": @(YES),
        @"path": path ?: @"",
        @"uri": uri ?: @"",
        @"width": @(size),
        @"height": @(size),
        @"fileName": fileName ?: @"",
        @"tempFilePath": path ?: @"",
        @"errorCode": @(0),
        @"errorMessage": @""
    };
}

static NSDictionary *hr_qrCodeFailResult(NSInteger errorCode, NSString *message) {
    return @{
        @"success": @(NO),
        @"path": @"",
        @"uri": @"",
        @"width": @(0),
        @"height": @(0),
        @"fileName": @"",
        @"tempFilePath": @"",
        @"errorCode": @(errorCode),
        @"errorMessage": message ?: @"二维码生成失败"
    };
}

static NSDictionary *hr_canvasCaptureFailResult(NSInteger errorCode, NSString *message) {
    return @{
        @"success": @(NO),
        @"path": @"",
        @"uri": @"",
        @"width": @(0),
        @"height": @(0),
        @"fileName": @"",
        @"tempFilePath": @"",
        @"errorCode": @(errorCode),
        @"errorMessage": message ?: @"截图失败"
    };
}

static inline void hr_dispatch_main(void (^block)(void)) {
    if (!block) {
        return;
    }
    if (NSThread.isMainThread) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

@interface HRBridgeModule () <KuiklyViewBaseDelegate>

@property (nonatomic, strong) HROffscreenRenderController *pendingOffscreenRenderController;

@end

@implementation HRBridgeModule

@synthesize hr_rootView;

+ (void)registerRouteResultCallbackWithId:(NSString *)requestId callback:(KuiklyRenderCallback)callback {
    [HRRouteResultCallbackCenter registerCallbackWithId:requestId callback:callback];
}

+ (void)removeRouteResultCallbackWithId:(NSString *)requestId {
    [HRRouteResultCallbackCenter removeCallbackWithId:requestId];
}

- (BOOL)hr_isProjectBridgeSelectorName:(NSString *)selectorName {
    id<KuiklyHostProjectBridgeProvider> provider = [KuiklyHostProviderRegistry projectBridgeProvider];
    if (!provider || selectorName.length == 0 || ![selectorName hasSuffix:@":"]) {
        return NO;
    }
    NSUInteger colonCount = selectorName.length - [[selectorName stringByReplacingOccurrencesOfString:@":" withString:@""] length];
    return colonCount == 1;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    return [self hr_isProjectBridgeSelectorName:NSStringFromSelector(aSelector)];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (signature) {
        return signature;
    }
    if ([self hr_isProjectBridgeSelectorName:NSStringFromSelector(aSelector)]) {
        return [NSMethodSignature signatureWithObjCTypes:"@@:@"];
    }
    return nil;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    NSString *selectorName = NSStringFromSelector(invocation.selector);
    if (![self hr_isProjectBridgeSelectorName:selectorName]) {
        [super forwardInvocation:invocation];
        return;
    }
    NSDictionary *args = nil;
    [invocation getArgument:&args atIndex:2];
    if (![args isKindOfClass:[NSDictionary class]]) {
        args = @{};
    }
    NSString *method = [selectorName substringToIndex:(selectorName.length - 1)];
    KuiklyRenderCallback callback = [self kr_callbackFromArgs:args];
    BOOL handled = [[KuiklyHostProviderRegistry projectBridgeProvider] handleMethod:method
                                                                               args:[self kr_paramsFromArgs:args]
                                                                     hostViewController:[self kr_hostViewController]
                                                                           callback:callback];
    if (!handled && callback) {
        callback(hr_bridge_result(-1, @"method does not exist"));
    }
    id result = nil;
    [invocation setReturnValue:&result];
}

- (NSDictionary *)kr_paramsFromArgs:(NSDictionary *)args {
    id rawParam = args[KR_PARAM_KEY];
    if ([rawParam isKindOfClass:[NSDictionary class]]) {
        return rawParam;
    }
    if ([rawParam isKindOfClass:[NSString class]]) {
        return [rawParam hr_stringToDictionary] ?: @{};
    }
    return @{};
}

- (KuiklyRenderCallback)kr_callbackFromArgs:(NSDictionary *)args {
    id callback = args[KR_CALLBACK_KEY];
    return callback ?: nil;
}

- (UIViewController *)kr_hostViewController {
    return self.hr_rootView ? hr_findViewControllerFromView(self.hr_rootView) : nil;
}

- (UIWindow *)kr_keyWindow {
#if TARGET_OS_OSX
    return NSApplication.sharedApplication.keyWindow ?: NSApplication.sharedApplication.mainWindow;
#else
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            if (windowScene.activationState != UISceneActivationStateForegroundActive) {
                continue;
            }
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
        }
    }
    return UIApplication.sharedApplication.keyWindow;
#endif
}

- (UIViewController *)kr_visibleViewControllerFrom:(UIViewController *)controller {
#if TARGET_OS_OSX
    return controller;
#else
    if (!controller) {
        return nil;
    }
    if (controller.presentedViewController) {
        return [self kr_visibleViewControllerFrom:controller.presentedViewController];
    }
    if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)controller;
        UIViewController *visible = navigationController.visibleViewController ?: navigationController.topViewController;
        return [self kr_visibleViewControllerFrom:visible] ?: navigationController;
    }
    if ([controller isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)controller;
        return [self kr_visibleViewControllerFrom:tabBarController.selectedViewController] ?: tabBarController;
    }
    return controller;
#endif
}

- (UIViewController *)kr_topViewController {
#if TARGET_OS_OSX
    return self.kr_keyWindow.contentViewController;
#else
    return [self kr_visibleViewControllerFrom:self.kr_keyWindow.rootViewController];
#endif
}

- (UIViewController *)kr_hostNavigationController {
#if TARGET_OS_OSX
    return [self kr_hostViewController] ?: [self kr_topViewController];
#else
    UIViewController *viewController = [self kr_hostViewController] ?: [self kr_topViewController];
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)viewController;
    }
    return viewController.navigationController;
#endif
}

- (void)toast:(NSDictionary *)args {
    NSString *content = [self kr_paramsFromArgs:args][@"content"];
    if ([content isKindOfClass:[NSString class]] && content.length > 0) {
        [[KuiklyHostProviderRegistry uiProvider] toastWithContent:content hostViewController:[self kr_hostViewController]];
    }
}

- (void)showCenterToast:(NSDictionary *)args {
    [[KuiklyHostProviderRegistry uiProvider] showCenterToastWithArgs:[self kr_paramsFromArgs:args] hostViewController:[self kr_hostViewController]];
}

- (void)copyToPasteboard:(NSDictionary *)args {
    NSString *content = [self kr_paramsFromArgs:args][@"content"];
    if ([content isKindOfClass:[NSString class]] && content.length > 0) {
        [[KuiklyHostProviderRegistry uiProvider] copyToPasteboardWithContent:content];
    }
}

- (void)showModal:(NSDictionary *)args {
    [[KuiklyHostProviderRegistry uiProvider] showModalWithArgs:[self kr_paramsFromArgs:args]
                                            hostViewController:[self kr_topViewController]
                                                      callback:[self kr_callbackFromArgs:args]];
}

- (void)showResultModal:(NSDictionary *)args {
    [[KuiklyHostProviderRegistry uiProvider] showResultModalWithArgs:[self kr_paramsFromArgs:args]
                                                  hostViewController:[self kr_topViewController]
                                                            callback:[self kr_callbackFromArgs:args]];
}

- (void)showNativeLoading:(NSDictionary *)args {
    NSString *content = [self kr_paramsFromArgs:args][@"content"];
    [[KuiklyHostProviderRegistry uiProvider] showLoadingWithContent:[content isKindOfClass:[NSString class]] ? content : nil
                                                          darkStyle:NO
                                                 hostViewController:[self kr_hostViewController]];
}

- (void)showNativeDarkLoading:(NSDictionary *)args {
    NSString *content = [self kr_paramsFromArgs:args][@"content"];
    [[KuiklyHostProviderRegistry uiProvider] showLoadingWithContent:[content isKindOfClass:[NSString class]] ? content : nil
                                                          darkStyle:YES
                                                 hostViewController:[self kr_hostViewController]];
}

- (void)hideNativeLoading:(NSDictionary *)args {
    __unused NSDictionary *unusedArgs = args;
    [[KuiklyHostProviderRegistry uiProvider] hideLoadingWithDarkStyle:NO hostViewController:[self kr_hostViewController]];
}

- (void)hideNativeDarkLoading:(NSDictionary *)args {
    __unused NSDictionary *unusedArgs = args;
    [[KuiklyHostProviderRegistry uiProvider] hideLoadingWithDarkStyle:YES hostViewController:[self kr_hostViewController]];
}

- (NSString *)closeKeyboard:(NSDictionary *)args {
    __unused NSDictionary *unusedArgs = args;
    return [[KuiklyHostProviderRegistry uiProvider] closeKeyboardForHostViewController:[self kr_hostViewController]];
}

- (void)closePage:(NSDictionary *)args {
    __unused NSDictionary *unusedArgs = args;
    [[KuiklyHostProviderRegistry pageProvider] finishTop:1 hostViewController:[self kr_hostViewController] ?: [self kr_topViewController]];
}

- (void)navigateBack:(NSDictionary *)args {
    NSDictionary *params = [self kr_paramsFromArgs:args];
    NSInteger delta = [params[@"delta"] integerValue];
    if (delta <= 0) {
        delta = 1;
    }
    NSDictionary *userData = [params[@"userData"] isKindOfClass:[NSDictionary class]] ? params[@"userData"] : nil;
    NSString *requestKey = [userData[HRRequestKeyParam] isKindOfClass:[NSString class]] ? userData[HRRequestKeyParam] : nil;
    NSDictionary *result = [userData[HRResultParam] isKindOfClass:[NSDictionary class]] ? userData[HRResultParam] : nil;
    if (requestKey.length > 0 && result.count > 0) {
        KuiklyRenderCallback callback = [HRRouteResultCallbackCenter consumeCallbackWithId:requestKey];
        if (callback) {
            callback(result);
        }
    }
    [[KuiklyHostProviderRegistry pageProvider] finishTop:delta hostViewController:[self kr_hostViewController] ?: [self kr_topViewController]];
}

- (void)openPage:(NSDictionary *)args {
    NSDictionary *params = [self kr_paramsFromArgs:args];
    KuiklyRenderCallback callback = [self kr_callbackFromArgs:args];
    NSString *url = [params[@"url"] isKindOfClass:[NSString class]] ? params[@"url"] : nil;
    NSDictionary *pageInfo = [HRRoutePageParser pageInfoFromURL:url ?: @""];
    NSString *pageName = pageInfo[@"pageName"];
    NSMutableDictionary *pageData = [pageInfo[@"pageData"] mutableCopy];
    NSDictionary *userData = [params[@"userData"] isKindOfClass:[NSDictionary class]] ? params[@"userData"] : nil;
    if (userData.count > 0) {
        [pageData addEntriesFromDictionary:userData];
    }
    if (pageName.length == 0) {
        return;
    }
    BOOL closeCurrent = [params[@"closeCurPage"] integerValue] == 1;
    UIViewController *hostViewController = [self kr_hostViewController] ?: [self kr_topViewController];
    id<KuiklyHostNativeRouteProvider> nativeRouteProvider = [KuiklyHostProviderRegistry nativeRouteProvider];
    BOOL handled = [nativeRouteProvider handleRouteWithName:pageName
                                                   pageData:pageData
                                         hostViewController:hostViewController
                                                   onResult:^(NSDictionary *result) {
        if (callback) {
            callback(result);
        }
    }];
    if (handled) {
        return;
    }
    UIViewController *routeController = [nativeRouteProvider viewControllerForRouteName:pageName
                                                                               pageData:pageData
                                                                     hostViewController:hostViewController
                                                                               onResult:^(NSDictionary *result) {
        if (callback) {
            callback(result);
        }
    }];
    if (routeController) {
#if TARGET_OS_OSX
        __unused UIViewController *unusedNavigationController = [self kr_hostNavigationController];
        return;
#else
        UINavigationController *navigationController = [self kr_hostNavigationController];
        [navigationController pushViewController:routeController animated:YES];
        return;
#endif
    }
    NSString *requestKey = [pageData[HRRequestKeyParam] isKindOfClass:[NSString class]] ? pageData[HRRequestKeyParam] : nil;
    if (requestKey.length > 0 && callback) {
        [HRRouteResultCallbackCenter registerCallbackWithId:requestKey callback:[callback copy]];
    }
    [[KuiklyHostProviderRegistry pageProvider] openKuiklyPageWithName:pageName
                                                             pageData:pageData
                                                   hostViewController:hostViewController
                                                         closeCurrent:closeCurrent
                                                           clearStack:NO];
}

- (void)reLaunch:(NSDictionary *)args {
    NSDictionary *params = [self kr_paramsFromArgs:args];
    NSString *url = [params[@"url"] isKindOfClass:[NSString class]] ? params[@"url"] : nil;
    NSDictionary *pageInfo = [HRRoutePageParser pageInfoFromURL:url ?: @""];
    NSString *pageName = pageInfo[@"pageName"];
    NSMutableDictionary *pageData = [pageInfo[@"pageData"] mutableCopy];
    NSDictionary *userData = [params[@"userData"] isKindOfClass:[NSDictionary class]] ? params[@"userData"] : nil;
    if (userData.count > 0) {
        [pageData addEntriesFromDictionary:userData];
    }
    if (pageName.length == 0) {
        return;
    }
    UIViewController *hostViewController = [self kr_hostViewController] ?: [self kr_topViewController];
    id<KuiklyHostNativeRouteProvider> nativeRouteProvider = [KuiklyHostProviderRegistry nativeRouteProvider];
    BOOL handled = [nativeRouteProvider handleRouteWithName:pageName pageData:pageData hostViewController:hostViewController onResult:nil];
    if (handled) {
        return;
    }
    UIViewController *routeController = [nativeRouteProvider viewControllerForRouteName:pageName pageData:pageData hostViewController:hostViewController onResult:nil];
    if (routeController) {
#if TARGET_OS_OSX
        __unused UIViewController *unusedNavigationController = [self kr_hostNavigationController];
        return;
#else
        UINavigationController *navigationController = [self kr_hostNavigationController];
        [navigationController setViewControllers:@[routeController] animated:YES];
        return;
#endif
    }
    [[KuiklyHostProviderRegistry pageProvider] openKuiklyPageWithName:pageName
                                                             pageData:pageData
                                                   hostViewController:hostViewController
                                                         closeCurrent:NO
                                                           clearStack:YES];
}

- (void)pickMedia:(NSDictionary *)args {
    [[KuiklyHostProviderRegistry mediaProvider] pickMediaWithArgs:[self kr_paramsFromArgs:args]
                                               hostViewController:[self kr_hostViewController]
                                                         callback:[self kr_callbackFromArgs:args]];
}

- (void)share:(NSDictionary *)args {
    [[KuiklyHostProviderRegistry mediaProvider] shareWithArgs:[self kr_paramsFromArgs:args]
                                           hostViewController:[self kr_hostViewController]
                                                     callback:[self kr_callbackFromArgs:args]];
}

- (void)saveToAlbum:(NSDictionary *)args {
    [[KuiklyHostProviderRegistry mediaProvider] saveToAlbumWithArgs:[self kr_paramsFromArgs:args]
                                                 hostViewController:[self kr_hostViewController]
                                                           callback:[self kr_callbackFromArgs:args]];
}

- (void)uploadOssImage:(NSDictionary *)args {
    [[KuiklyHostProviderRegistry mediaProvider] uploadOssImageWithArgs:[self kr_paramsFromArgs:args]
                                                    hostViewController:[self kr_hostViewController]
                                                              callback:[self kr_callbackFromArgs:args]];
}

- (void)scanCode:(NSDictionary *)args {
    [[KuiklyHostProviderRegistry scanProvider] scanWithArgs:[self kr_paramsFromArgs:args]
                                         hostViewController:[self kr_hostViewController]
                                                   callback:[self kr_callbackFromArgs:args]];
}

- (void)fetchCachedFromNative:(NSDictionary *)args {
    NSDictionary *params = [self kr_paramsFromArgs:args];
    NSString *key = [params[@"key"] isKindOfClass:[NSString class]] ? params[@"key"] : nil;
    KuiklyRenderCallback callback = [self kr_callbackFromArgs:args];
    if (!callback || key.length == 0) {
        return;
    }
    id value = [NSUserDefaults.standardUserDefaults objectForKey:key];
    callback(@{
        @"value": value ?: [NSNull null]
    });
}

- (NSString *)getCachedFromNative:(NSDictionary *)args {
    NSDictionary *params = [self kr_paramsFromArgs:args];
    NSString *key = [params[@"key"] isKindOfClass:[NSString class]] ? params[@"key"] : nil;
    id value = key.length > 0 ? [NSUserDefaults.standardUserDefaults objectForKey:key] : nil;
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    if (value) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:value options:0 error:nil];
        if (data) {
            return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    return nil;
}

- (void)setCachedToNative:(NSDictionary *)args {
    NSDictionary *params = [self kr_paramsFromArgs:args];
    NSString *key = [params[@"key"] isKindOfClass:[NSString class]] ? params[@"key"] : nil;
    id value = params[@"value"];
    if (key.length == 0) {
        return;
    }
    if (value) {
        [NSUserDefaults.standardUserDefaults setObject:value forKey:key];
    } else {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:key];
    }
}

- (void)preDownloadImage:(NSDictionary *)args {
    NSDictionary *params = [self kr_paramsFromArgs:args];
    KuiklyRenderCallback callback = [self kr_callbackFromArgs:args];
    NSString *urlString = [params[@"url"] isKindOfClass:[NSString class]] ? params[@"url"] : nil;
    NSURL *url = [NSURL URLWithString:urlString ?: @""];
    if (!url) {
        if (callback) {
            callback(hr_bridge_result(-1, @"invalid url"));
        }
        return;
    }
    [[SDWebImageManager sharedManager] loadImageWithURL:url
                                                options:0
                                                context:nil
                                               progress:nil
                                              completed:^(__unused UIImage * _Nullable image,
                                                          __unused NSData * _Nullable data,
                                                          NSError * _Nullable error,
                                                          __unused SDImageCacheType cacheType,
                                                          BOOL finished,
                                                          __unused NSURL * _Nullable imageURL) {
        if (!callback) {
            return;
        }
        callback(error ? hr_bridge_result(-1, error.localizedDescription ?: @"preload failed") :
                 @{@"code": @(0), @"finished": @(finished)});
    }];
}
- (void)preDownloadPAGResource:(NSDictionary *)args { __unused NSDictionary *unusedArgs = args; }
- (void)preDownloadAPNGResource:(NSDictionary *)args { __unused NSDictionary *unusedArgs = args; }
- (void)updateOfflineIfNeed:(NSDictionary *)args { __unused NSDictionary *unusedArgs = args; }

- (void)generateQrCode:(NSDictionary *)args {
    NSDictionary *params = [self kr_paramsFromArgs:args];
    KuiklyRenderCallback callback = [self kr_callbackFromArgs:args];
    NSString *text = [params[@"text"] isKindOfClass:[NSString class]] ? params[@"text"] : nil;
    NSInteger size = [params[@"size"] integerValue];
    NSInteger margin = [params[@"margin"] integerValue];
    if (text.length == 0 || size <= 0) {
        if (callback) {
            callback(hr_qrCodeFailResult(2, @"参数错误"));
        }
        return;
    }
    hr_dispatch_main(^{
        CGSize targetSize = CGSizeMake(size, size);
        __block UIImage *qrImage = nil;
        Class terminalHelpClass = hr_swiftClassNamed(@"TerminalHelp");
        SEL qrSelector = NSSelectorFromString(@"showQrCodeWithQrUrl:size:imageBlock:");
        if (!terminalHelpClass || ![terminalHelpClass respondsToSelector:qrSelector]) {
            if (callback) {
                callback(hr_qrCodeFailResult(3, @"二维码能力不可用"));
            }
            return;
        }
        typedef void (*HRGenerateQrCodeIMP)(id, SEL, NSString *, CGSize, void (^)(UIImage *));
        HRGenerateQrCodeIMP qrImp = (HRGenerateQrCodeIMP)[terminalHelpClass methodForSelector:qrSelector];
        qrImp(terminalHelpClass, qrSelector, text, targetSize, ^(UIImage * _Nonnull image) {
            qrImage = image;
        });
        if (!qrImage) {
            if (callback) {
                callback(hr_qrCodeFailResult(3, @"二维码生成失败"));
            }
            return;
        }
        UIImage *finalImage = hr_imageByApplyingMargin(qrImage, margin);
        NSData *imageData = UIImagePNGRepresentation(finalImage);
        if (imageData.length == 0) {
            if (callback) {
                callback(hr_qrCodeFailResult(4, @"二维码落盘失败"));
            }
            return;
        }
        NSString *dirPath = hr_qrCodeDirectoryPath();
        NSError *directoryError = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&directoryError];
        if (directoryError) {
            if (callback) {
                callback(hr_qrCodeFailResult(5, directoryError.localizedDescription ?: @"目录创建失败"));
            }
            return;
        }
        NSString *fileName = [NSString stringWithFormat:@"qr_%@.png", NSUUID.UUID.UUIDString];
        NSString *filePath = [dirPath stringByAppendingPathComponent:fileName];
        BOOL writeSuccess = [imageData writeToFile:filePath atomically:YES];
        if (!writeSuccess) {
            if (callback) {
                callback(hr_qrCodeFailResult(6, @"二维码写入失败"));
            }
            return;
        }
        if (callback) {
            callback(hr_qrCodeSuccessResult(filePath, fileName, size));
        }
    });
}

- (void)canvasToTempFilePath:(NSDictionary *)args {
    NSDictionary *params = [self kr_paramsFromArgs:args];
    KuiklyRenderCallback callback = [self kr_callbackFromArgs:args];
    NSString *pageName = [params[@"pageName"] isKindOfClass:[NSString class]] ? params[@"pageName"] : nil;
    CGFloat width = [params[@"width"] doubleValue];
    CGFloat height = [params[@"height"] doubleValue];
    BOOL saveToAlbum = [params[@"saveToAlbum"] boolValue];
    NSInteger delayMillis = [params[@"delayMillis"] respondsToSelector:@selector(integerValue)] ? [params[@"delayMillis"] integerValue] : 800;
    if (delayMillis <= 0) {
        delayMillis = 800;
    }
    if (pageName.length == 0 || width <= 0 || height <= 0) {
        if (callback) {
            callback(hr_canvasCaptureFailResult(1, @"截图参数无效"));
        }
        return;
    }
    hr_dispatch_main(^{
        UIViewController *hostViewController = [self kr_topViewController];
        UIView *hostView = hostViewController.view;
        if (!hostView) {
            if (callback) {
                callback(hr_canvasCaptureFailResult(2, @"宿主根视图不可用"));
            }
            return;
        }
        [self.pendingOffscreenRenderController cancel];
        self.pendingOffscreenRenderController =
            [[HROffscreenRenderController alloc] initWithHostView:hostView
                                                         pageName:pageName
                                                         pageData:@{}
                                                            width:width
                                                           height:height
                                                      delayMillis:delayMillis
                                                      saveToAlbum:saveToAlbum
                                                         callback:^(NSDictionary *result) {
            self.pendingOffscreenRenderController = nil;
            if (callback) {
                callback(result);
            }
        }];
        [self.pendingOffscreenRenderController start];
    });
}

- (void)cleanupPendingCanvasCaptureView {
    [self.pendingOffscreenRenderController cancel];
    self.pendingOffscreenRenderController = nil;
}

- (void)finishPendingCanvasCapture {
    [self cleanupPendingCanvasCaptureView];
}

- (void)schedulePendingCanvasCapture {
    [self finishPendingCanvasCapture];
}

- (void)fetchContextCodeWithPageName:(NSString *)pageName resultCallback:(KuiklyContextCodeCallback)callback {
    __unused NSString *unusedPageName = pageName;
    if (callback) {
        callback([KuiklyHostSupportConfiguration currentConfiguration].contextCode ?: @"Shared", nil);
    }
}

- (UIView *)createLoadingView {
    UIView *loadingView = [[UIView alloc] init];
    loadingView.backgroundColor = UIColor.whiteColor;
    return loadingView;
}

- (UIView *)createErrorView {
    UIView *errorView = [[UIView alloc] init];
    errorView.backgroundColor = UIColor.whiteColor;
    return errorView;
}

- (void)contentViewDidLoad {
    [self schedulePendingCanvasCapture];
}

@end
