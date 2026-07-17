#import "KuiklyHostSupportConfiguration.h"

static KuiklyHostSupportConfiguration *gCurrentConfiguration = nil;

@implementation KuiklyHostSupportConfiguration

+ (instancetype)defaultConfiguration {
    KuiklyHostSupportConfiguration *configuration = [[KuiklyHostSupportConfiguration alloc] init];
    configuration.contextCode = @"Shared";
    return configuration;
}

+ (instancetype)currentConfiguration {
    @synchronized (self) {
        if (!gCurrentConfiguration) {
            gCurrentConfiguration = [[self defaultConfiguration] copy];
        }
        return gCurrentConfiguration;
    }
}

+ (void)installConfiguration:(KuiklyHostSupportConfiguration *)configuration {
    @synchronized (self) {
        gCurrentConfiguration = [(configuration ?: [self defaultConfiguration]) copy];
    }
}

- (id)copyWithZone:(NSZone *)zone {
    KuiklyHostSupportConfiguration *configuration = [[[self class] allocWithZone:zone] init];
    configuration.contextCode = self.contextCode ?: @"Shared";
    configuration.progressHUDClassName = self.progressHUDClassName;
    configuration.loadingIndicatorClassName = self.loadingIndicatorClassName;
    configuration.photoPermissionBridgeClassName = self.photoPermissionBridgeClassName;
    return configuration;
}

@end
