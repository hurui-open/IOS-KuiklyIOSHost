#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 对齐 Android RuntimeInstaller，仅约定安装时机，不直接耦合 shared 实现。
@interface KuiklyHostRuntimeInstaller : NSObject

@property (nonatomic, copy, readonly) dispatch_block_t installBlock;

- (instancetype)initWithInstallBlock:(dispatch_block_t)installBlock;

@end

NS_ASSUME_NONNULL_END
