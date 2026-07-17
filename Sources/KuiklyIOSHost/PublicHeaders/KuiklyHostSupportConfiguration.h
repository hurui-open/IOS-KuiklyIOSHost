#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Kuikly iOS Host 运行支持配置。
@interface KuiklyHostSupportConfiguration : NSObject <NSCopying>

@property (nonatomic, copy) NSString *contextCode;
@property (nonatomic, copy, nullable) NSString *progressHUDClassName;
@property (nonatomic, copy, nullable) NSString *loadingIndicatorClassName;
@property (nonatomic, copy, nullable) NSString *photoPermissionBridgeClassName;

+ (instancetype)defaultConfiguration;
+ (instancetype)currentConfiguration;
+ (void)installConfiguration:(KuiklyHostSupportConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
