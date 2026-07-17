#import "KuiklyHostRuntimeInstaller.h"

@implementation KuiklyHostRuntimeInstaller

- (instancetype)initWithInstallBlock:(dispatch_block_t)installBlock {
    self = [super init];
    if (self) {
        _installBlock = [installBlock copy];
    }
    return self;
}

@end
