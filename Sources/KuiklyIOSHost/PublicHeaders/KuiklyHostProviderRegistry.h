#import <Foundation/Foundation.h>
#import "KuiklyPlatformCompat.h"

NS_ASSUME_NONNULL_BEGIN

@protocol KuiklyHostProvider <NSObject>
@end

@protocol KuiklyHostUiProvider <KuiklyHostProvider>
- (void)toastWithContent:(NSString *)content hostViewController:(UIViewController * _Nullable)hostViewController;
- (void)showCenterToastWithArgs:(NSDictionary *)args hostViewController:(UIViewController * _Nullable)hostViewController;
- (void)showModalWithArgs:(NSDictionary *)args hostViewController:(UIViewController * _Nullable)hostViewController callback:(KuiklyRenderCallback _Nullable)callback;
- (void)showResultModalWithArgs:(NSDictionary *)args hostViewController:(UIViewController * _Nullable)hostViewController callback:(KuiklyRenderCallback _Nullable)callback;
- (void)showLoadingWithContent:(NSString * _Nullable)content darkStyle:(BOOL)darkStyle hostViewController:(UIViewController * _Nullable)hostViewController;
- (void)hideLoadingWithDarkStyle:(BOOL)darkStyle hostViewController:(UIViewController * _Nullable)hostViewController;
- (void)copyToPasteboardWithContent:(NSString *)content;
- (NSString * _Nullable)closeKeyboardForHostViewController:(UIViewController * _Nullable)hostViewController;
@end

@protocol KuiklyHostScanProvider <KuiklyHostProvider>
- (void)scanWithArgs:(NSDictionary *)args hostViewController:(UIViewController * _Nullable)hostViewController callback:(KuiklyRenderCallback _Nullable)callback;
@end

@protocol KuiklyHostMediaProvider <KuiklyHostProvider>
- (void)pickMediaWithArgs:(NSDictionary *)args hostViewController:(UIViewController * _Nullable)hostViewController callback:(KuiklyRenderCallback _Nullable)callback;
- (void)shareWithArgs:(NSDictionary *)args hostViewController:(UIViewController * _Nullable)hostViewController callback:(KuiklyRenderCallback _Nullable)callback;
- (void)saveToAlbumWithArgs:(NSDictionary *)args hostViewController:(UIViewController * _Nullable)hostViewController callback:(KuiklyRenderCallback _Nullable)callback;
- (void)uploadOssImageWithArgs:(NSDictionary *)args hostViewController:(UIViewController * _Nullable)hostViewController callback:(KuiklyRenderCallback _Nullable)callback;
@end

@protocol KuiklyHostNativeRouteProvider <KuiklyHostProvider>
- (BOOL)handleRouteWithName:(NSString *)name
                   pageData:(NSDictionary *)pageData
         hostViewController:(UIViewController * _Nullable)hostViewController
                   onResult:(void (^ _Nullable)(NSDictionary *result))onResult;
- (UIViewController * _Nullable)viewControllerForRouteName:(NSString *)name
                                                  pageData:(NSDictionary *)pageData
                                        hostViewController:(UIViewController * _Nullable)hostViewController
                                                  onResult:(void (^ _Nullable)(NSDictionary *result))onResult;
@end

@protocol KuiklyHostPageProvider <KuiklyHostProvider>
- (void)openKuiklyPageWithName:(NSString *)pageName
                      pageData:(NSDictionary *)pageData
            hostViewController:(UIViewController * _Nullable)hostViewController
                  closeCurrent:(BOOL)closeCurrent
                    clearStack:(BOOL)clearStack;
- (void)finishTop:(NSInteger)delta hostViewController:(UIViewController * _Nullable)hostViewController;
@end

@protocol KuiklyHostProjectBridgeProvider <KuiklyHostProvider>
- (BOOL)handleMethod:(NSString *)method
                args:(NSDictionary *)args
  hostViewController:(UIViewController * _Nullable)hostViewController
            callback:(KuiklyRenderCallback _Nullable)callback;
@end

@interface KuiklyDefaultUiProvider : NSObject <KuiklyHostUiProvider>
@end

@interface KuiklyDefaultScanProvider : NSObject <KuiklyHostScanProvider>
@end

@interface KuiklyDefaultMediaProvider : NSObject <KuiklyHostMediaProvider>
@end

@interface KuiklyDefaultNativeRouteProvider : NSObject <KuiklyHostNativeRouteProvider>
@end

@interface KuiklyDefaultPageProvider : NSObject <KuiklyHostPageProvider>
@end

@interface KuiklyDefaultProjectBridgeProvider : NSObject <KuiklyHostProjectBridgeProvider>
@end

/// 提供一个开箱即用的 UINavigationController 承载实现，方便接入方快速落地。
@interface KuiklyNavigationPageProvider : NSObject <KuiklyHostPageProvider>
@end

@interface KuiklyHostProviderRegistry : NSObject

+ (id<KuiklyHostUiProvider>)uiProvider;
+ (id<KuiklyHostScanProvider>)scanProvider;
+ (id<KuiklyHostMediaProvider>)mediaProvider;
+ (id<KuiklyHostNativeRouteProvider>)nativeRouteProvider;
+ (id<KuiklyHostPageProvider>)pageProvider;
+ (id<KuiklyHostProjectBridgeProvider>)projectBridgeProvider;

+ (void)installProviders:(NSArray<id<KuiklyHostProvider>> *)providers;

@end

NS_ASSUME_NONNULL_END
