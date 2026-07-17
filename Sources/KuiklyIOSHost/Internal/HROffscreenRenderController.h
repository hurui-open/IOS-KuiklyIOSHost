#import <Foundation/Foundation.h>
#import "KuiklyPlatformCompat.h"

NS_ASSUME_NONNULL_BEGIN

@interface HROffscreenRenderController : NSObject

- (instancetype)initWithHostView:(UIView *)hostView
                        pageName:(NSString *)pageName
                        pageData:(NSDictionary *)pageData
                           width:(CGFloat)width
                          height:(CGFloat)height
                     delayMillis:(NSInteger)delayMillis
                     saveToAlbum:(BOOL)saveToAlbum
                        callback:(KuiklyRenderCallback)callback;

- (void)start;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
