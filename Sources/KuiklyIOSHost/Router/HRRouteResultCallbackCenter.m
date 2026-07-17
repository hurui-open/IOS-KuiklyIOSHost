#import "HRRouteResultCallbackCenter.h"

@implementation HRRouteResultCallbackCenter

/**
 * requestKey / callbackId -> KuiklyRenderCallback
 *
 * 说明：
 * - 这里只保存当前进程内有效的回调
 * - 回调触发后会被立即移除
 */
static NSMutableDictionary<NSString *, id> *hr_routerResultCallbacks = nil;

static inline NSMutableDictionary<NSString *, id> *hr_result_callback_map(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hr_routerResultCallbacks = [NSMutableDictionary dictionary];
    });
    return hr_routerResultCallbacks;
}

/**
 * 注册回调到统一结果中心。
 */
+ (void)registerCallbackWithId:(NSString *)requestId callback:(KuiklyRenderCallback)callback {
    if (requestId.length == 0 || !callback) {
        return;
    }
    hr_result_callback_map()[requestId] = [callback copy];
}

/**
 * 主动移除回调。
 */
+ (void)removeCallbackWithId:(NSString *)requestId {
    if (requestId.length == 0) {
        return;
    }
    [hr_result_callback_map() removeObjectForKey:requestId];
}

/**
 * 取出并移除回调。
 *
 * 返回 nil 表示：
 * - requestId 不存在
 * - 或者该回调已经被消费过
 */
+ (KuiklyRenderCallback)consumeCallbackWithId:(NSString *)requestId {
    if (requestId.length == 0) {
        return nil;
    }
    KuiklyRenderCallback callback = hr_result_callback_map()[requestId];
    if (callback) {
        [hr_result_callback_map() removeObjectForKey:requestId];
    }
    return callback;
}

@end
