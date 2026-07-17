#import "HROffscreenRenderController.h"

#import <Photos/Photos.h>
#import "KuiklyHostSupportConfiguration.h"

static NSString *hr_offscreen_capture_directory_path(void) {
    NSArray<NSURL *> *cacheURLs = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory
                                                                         inDomains:NSUserDomainMask];
    NSURL *cacheURL = cacheURLs.firstObject;
    if (!cacheURL) {
        return NSTemporaryDirectory();
    }
    NSURL *dirURL = [cacheURL URLByAppendingPathComponent:@"kuikly_capture" isDirectory:YES];
    return dirURL.path;
}

static NSDictionary *hr_offscreen_capture_fail_result(NSInteger errorCode, NSString *message) {
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

static NSDictionary *hr_offscreen_capture_success_result(NSString *path, NSInteger width, NSInteger height) {
    NSString *fileName = path.lastPathComponent ?: @"";
    return @{
        @"success": @(YES),
        @"path": path ?: @"",
        @"uri": path.length > 0 ? [@"file://" stringByAppendingString:path] : @"",
        @"width": @(width),
        @"height": @(height),
        @"fileName": fileName,
        @"tempFilePath": path ?: @"",
        @"errorCode": @(0),
        @"errorMessage": @""
    };
}

static inline void hr_offscreen_dispatch_main(void (^block)(void)) {
    if (!block) {
        return;
    }
    if (NSThread.isMainThread) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

static void hr_offscreen_request_photo_library_add_authorization(void (^completion)(BOOL granted, NSString *message)) {
    if (!completion) {
        return;
    }
    PHAuthorizationStatus status = PHPhotoLibrary.authorizationStatus;
    BOOL isAuthorized = status == PHAuthorizationStatusAuthorized;
    if (@available(iOS 14.0, *)) {
        isAuthorized = isAuthorized || status == PHAuthorizationStatusLimited;
    }
    if (isAuthorized) {
        completion(YES, nil);
        return;
    }
    if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
        completion(NO, @"当前无相册权限");
        return;
    }
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus newStatus) {
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL isAuthorizedStatus = newStatus == PHAuthorizationStatusAuthorized;
            if (@available(iOS 14.0, *)) {
                isAuthorizedStatus = isAuthorizedStatus || newStatus == PHAuthorizationStatusLimited;
            }
            if (isAuthorizedStatus) {
                completion(YES, nil);
            } else {
                completion(NO, @"当前无相册权限");
            }
        });
    }];
}

static UIImage *hr_offscreen_snapshot_image_from_view(UIView *view) {
    if (!view || CGRectGetWidth(view.bounds) <= 0 || CGRectGetHeight(view.bounds) <= 0) {
        return nil;
    }
#if TARGET_OS_OSX
    NSBitmapImageRep *rep = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
    if (!rep) {
        return nil;
    }
    [view cacheDisplayInRect:view.bounds toBitmapImageRep:rep];
    NSImage *image = [[NSImage alloc] initWithSize:view.bounds.size];
    [image addRepresentation:rep];
    return image;
#else
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:view.bounds.size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    }];
#endif
}

static void hr_offscreen_save_image_to_photo_library(UIImage *image, void (^completion)(BOOL success, NSString *message)) {
    if (!completion) {
        return;
    }
    if (!image) {
        completion(NO, @"图片为空");
        return;
    }
    hr_offscreen_request_photo_library_add_authorization(^(BOOL granted, NSString *message) {
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

@interface HROffscreenRenderController () <KuiklyRenderViewControllerBaseDelegatorDelegate>

@property (nonatomic, weak) UIView *hostView;
@property (nonatomic, copy) NSString *pageName;
@property (nonatomic, strong) NSDictionary *pageData;
@property (nonatomic, assign) CGFloat targetWidth;
@property (nonatomic, assign) CGFloat targetHeight;
@property (nonatomic, assign) NSInteger delayMillis;
@property (nonatomic, assign) BOOL saveToAlbum;
@property (nonatomic, copy) KuiklyRenderCallback callback;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) KuiklyRenderViewControllerBaseDelegator *delegator;
@property (nonatomic, copy) NSString *captureToken;
@property (nonatomic, assign) BOOL captureScheduled;
@property (nonatomic, assign) BOOL renderContentReady;
@property (nonatomic, assign) BOOL cleanedUp;

@end

@implementation HROffscreenRenderController

- (instancetype)initWithHostView:(UIView *)hostView
                        pageName:(NSString *)pageName
                        pageData:(NSDictionary *)pageData
                           width:(CGFloat)width
                          height:(CGFloat)height
                     delayMillis:(NSInteger)delayMillis
                     saveToAlbum:(BOOL)saveToAlbum
                        callback:(KuiklyRenderCallback)callback {
    if (self = [super init]) {
        _hostView = hostView;
        _pageName = [pageName copy] ?: @"";
        _pageData = [pageData copy] ?: @{};
        _targetWidth = width;
        _targetHeight = height;
        _delayMillis = delayMillis > 0 ? delayMillis : 800;
        _saveToAlbum = saveToAlbum;
        _callback = [callback copy];
    }
    return self;
}

- (void)start {
    hr_offscreen_dispatch_main(^{
        UIView *hostView = self.hostView;
        if (!hostView) {
            [self finishWithResult:hr_offscreen_capture_fail_result(2, @"宿主根视图不可用")];
            return;
        }

        [self cancel];

        CGRect frame = CGRectMake(CGRectGetWidth(hostView.bounds) + 2000.0, 0, self.targetWidth, self.targetHeight);
        UIView *containerView = [[UIView alloc] initWithFrame:frame];
        containerView.alpha = 0.0;
        containerView.userInteractionEnabled = NO;
        self.containerView = containerView;
        [hostView addSubview:containerView];

        NSMutableDictionary *pageData = [self.pageData mutableCopy] ?: [NSMutableDictionary new];
        pageData[@"hr_disablePerformance"] = @YES;

        KuiklyRenderViewControllerBaseDelegator *delegator =
            [[KuiklyRenderViewControllerBaseDelegator alloc] initWithPageName:self.pageName
                                                                     pageData:pageData
                                                                frameworkName:nil];
        delegator.delegate = self;
        delegator.emitPagerVisibilityEvents = NO;
        self.delegator = delegator;

        self.captureToken = NSUUID.UUID.UUIDString;
        self.captureScheduled = NO;
        self.renderContentReady = NO;
        self.cleanedUp = NO;

        [delegator viewDidLoadWithView:containerView];
        [delegator viewDidLayoutSubviews];
        [delegator viewWillAppear];
        [delegator viewDidAppear];
#if TARGET_OS_OSX
        if (NSApplication.sharedApplication.isActive) {
            [delegator notifyApplicationDidBecomeActive];
        }
#else
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            [delegator notifyApplicationDidBecomeActive];
        }
#endif

        [self scheduleTimeoutIfNeeded];
    });
}

- (void)cancel {
    hr_offscreen_dispatch_main(^{
        [self cleanup];
    });
}

- (void)cleanup {
    if (self.cleanedUp) {
        return;
    }
    self.cleanedUp = YES;

    if (self.delegator) {
        [self.delegator notifyApplicationWillResignActive];
        [self.delegator viewWillDisappear];
        [self.delegator viewDidDisappear];
    }
    [self.containerView removeFromSuperview];

    self.containerView = nil;
    self.delegator = nil;
    self.captureToken = nil;
    self.captureScheduled = NO;
    self.renderContentReady = NO;
}

- (void)finishWithResult:(NSDictionary *)result {
    KuiklyRenderCallback callback = self.callback;
    [self cleanup];
    if (callback) {
        callback(result ?: hr_offscreen_capture_fail_result(9, @"截图结果为空"));
    }
}

- (void)scheduleCaptureIfNeeded {
    if (!self.delegator || !self.containerView || self.captureScheduled || !self.renderContentReady) {
        return;
    }
    self.captureScheduled = YES;
    NSString *captureToken = self.captureToken ?: NSUUID.UUID.UUIDString;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delayMillis * NSEC_PER_MSEC)),
                   dispatch_get_main_queue(), ^{
        if (!self.delegator || !self.containerView) {
            return;
        }
        if (![self.captureToken isEqualToString:captureToken]) {
            return;
        }
        [self captureNow];
    });
}

- (void)scheduleTimeoutIfNeeded {
    NSString *captureToken = self.captureToken ?: NSUUID.UUID.UUIDString;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((self.delayMillis + 3000) * NSEC_PER_MSEC)),
                   dispatch_get_main_queue(), ^{
        if (!self.delegator || !self.containerView) {
            return;
        }
        if (![self.captureToken isEqualToString:captureToken]) {
            return;
        }
        [self finishWithResult:hr_offscreen_capture_fail_result(6, @"离屏截图超时")];
    });
}

- (void)captureNow {
    UIView *captureTarget = self.delegator.renderView ?: self.containerView;
    [self.containerView setNeedsLayout];
    [self.containerView layoutIfNeeded];
    [captureTarget setNeedsLayout];
    [captureTarget layoutIfNeeded];

    UIImage *snapshotImage = hr_offscreen_snapshot_image_from_view(captureTarget);
    if (!snapshotImage || snapshotImage.size.width <= 0 || snapshotImage.size.height <= 0) {
        [self finishWithResult:hr_offscreen_capture_fail_result(3, @"离屏截图失败")];
        return;
    }

    NSString *dirPath = hr_offscreen_capture_directory_path();
    NSError *directoryError = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:dirPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&directoryError];
    if (directoryError) {
        [self finishWithResult:hr_offscreen_capture_fail_result(4, directoryError.localizedDescription ?: @"截图目录创建失败")];
        return;
    }

    NSString *fileName = [NSString stringWithFormat:@"capture_%@.png", NSUUID.UUID.UUIDString];
    NSString *filePath = [dirPath stringByAppendingPathComponent:fileName];
    NSData *imageData = UIImagePNGRepresentation(snapshotImage);
    BOOL writeSuccess = imageData.length > 0 && [imageData writeToFile:filePath atomically:YES];
    if (!writeSuccess) {
        [self finishWithResult:hr_offscreen_capture_fail_result(5, @"截图文件写入失败")];
        return;
    }

    NSInteger width = (NSInteger)CGRectGetWidth(captureTarget.bounds);
    NSInteger height = (NSInteger)CGRectGetHeight(captureTarget.bounds);
    NSDictionary *successResult = hr_offscreen_capture_success_result(filePath, width, height);
    if (!self.saveToAlbum) {
        [self finishWithResult:successResult];
        return;
    }

    hr_offscreen_save_image_to_photo_library(snapshotImage, ^(__unused BOOL success, __unused NSString *message) {
        [self finishWithResult:successResult];
    });
}

#pragma mark - KuiklyRenderViewControllerBaseDelegatorDelegate

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
    self.renderContentReady = YES;
    [self scheduleCaptureIfNeeded];
}

@end
