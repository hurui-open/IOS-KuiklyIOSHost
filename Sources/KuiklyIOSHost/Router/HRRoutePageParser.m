#import "HRRoutePageParser.h"

@implementation HRRoutePageParser

/**
 * 把 `pageName&k=v` 形式的字符串拆成页面名和参数字典。
 *
 * 逻辑步骤：
 * 1. 第一个 `&` 之前的内容当作 pageName
 * 2. 后续每个 `k=v` 解析进 pageData
 * 3. 无法识别的片段直接跳过，不抛异常
 */
+ (NSDictionary *)pageInfoFromURL:(NSString *)url {
    if (url.length == 0) {
        return @{ @"pageName": @"", @"pageData": @{} };
    }
    NSArray<NSString *> *parts = [url componentsSeparatedByString:@"&"];
    NSString *pageName = parts.firstObject ?: @"";
    NSMutableDictionary *pageData = [NSMutableDictionary dictionary];
    for (NSUInteger idx = 1; idx < parts.count; idx++) {
        NSString *item = parts[idx];
        NSRange range = [item rangeOfString:@"="];
        if (range.location == NSNotFound) {
            continue;
        }
        NSString *key = [item substringToIndex:range.location];
        NSString *value = [item substringFromIndex:(range.location + 1)];
        NSString *decodedValue = [value stringByRemovingPercentEncoding] ?: value;
        if (key.length > 0) {
            pageData[key] = decodedValue ?: @"";
        }
    }
    return @{
        @"pageName": pageName,
        @"pageData": pageData
    };
}

@end
