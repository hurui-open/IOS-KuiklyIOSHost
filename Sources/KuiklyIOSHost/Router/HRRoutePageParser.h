#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * iOS 路由 URL 解析器。
 *
 * 职责：
 * - 把 Kuikly 传下来的 url 拆成 pageName 和 pageData
 * - 保持解析逻辑从 `HRBridgeModule` 主入口里独立出来
 */
@interface HRRoutePageParser : NSObject

/**
 * 解析 Kuikly 路由 url。
 *
 * @param url 约定格式：`pageName&key=value&key2=value2`
 *
 * @return 统一字典结构：
 * - `pageName`: 目标页面标识 / routeKey
 * - `pageData`: 解析出的 query 参数
 */
+ (NSDictionary *)pageInfoFromURL:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
