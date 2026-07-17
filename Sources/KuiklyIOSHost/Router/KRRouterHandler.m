#import "KRRouterHandler.h"

#import "KuiklyHostProviderRegistry.h"
#import "KuiklyPlatformCompat.h"

@implementation KRRouterHandler

+ (void)load {
    [KRRouterModule registerRouterHandler:[self new]];
}

- (void)openPageWithName:(NSString *)pageName pageData:(NSDictionary *)pageData controller:(UIViewController *)controller {
    [[KuiklyHostProviderRegistry pageProvider] openKuiklyPageWithName:pageName
                                                             pageData:pageData ?: @{}
                                                   hostViewController:controller
                                                         closeCurrent:NO
                                                           clearStack:NO];
}

- (void)closePage:(UIViewController *)controller {
    [[KuiklyHostProviderRegistry pageProvider] finishTop:1 hostViewController:controller];
}

@end
