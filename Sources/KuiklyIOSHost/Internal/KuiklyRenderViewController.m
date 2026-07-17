#import "KuiklyRenderViewController.h"
#import "KuiklyHostSupportConfiguration.h"
#import "KuiklyPlatformCompat.h"

@interface KuiklyRenderViewController()<KuiklyRenderViewControllerBaseDelegatorDelegate>

@property (nonatomic, strong) KuiklyRenderViewControllerBaseDelegator *delegator;

@end

@implementation KuiklyRenderViewController {
    NSDictionary *_pageData;
}

- (instancetype)initWithPageName:(NSString *)pageName pageData:(NSDictionary *)pageData {
    if (self = [super init]) {
        pageData = [self p_mergeExtParamsWithOriditalParam:pageData];
        _pageData = pageData;
        _delegator = [[KuiklyRenderViewControllerBaseDelegator alloc] initWithPageName:pageName pageData:pageData];
        _delegator.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
#if TARGET_OS_OSX
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = NSColor.whiteColor.CGColor;
#else
    self.view.backgroundColor = [UIColor whiteColor];
#endif
    [_delegator viewDidLoadWithView:self.view];
#if !TARGET_OS_OSX
    [self.navigationController setNavigationBarHidden:YES animated:NO];
#endif

}

#if TARGET_OS_OSX
- (void)viewDidLayout {
    [super viewDidLayout];
    [_delegator viewDidLayoutSubviews];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    [_delegator viewWillAppear];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    [_delegator viewDidAppear];
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    [_delegator viewWillDisappear];
}

- (void)viewDidDisappear {
    [super viewDidDisappear];
    [_delegator viewDidDisappear];
}
#else
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [_delegator viewDidLayoutSubviews];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_delegator viewWillAppear];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_delegator viewDidAppear];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_delegator viewWillDisappear];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_delegator viewDidDisappear];
}
#endif

#pragma mark - private

- (NSDictionary *)p_mergeExtParamsWithOriditalParam:(NSDictionary *)pageParam {
    NSMutableDictionary *mParam = [(pageParam ?: @{}) mutableCopy];

    return mParam;
}

#pragma mark - KuiklyRenderViewControllerDelegatorDelegate

- (UIView *)createLoadingView {
    UIView *loadingView = [[UIView alloc] init];
    loadingView.backgroundColor = [UIColor whiteColor];
    return loadingView;
}

- (UIView *)createErrorView {
    UIView *errorView = [[UIView alloc] init];
    errorView.backgroundColor = [UIColor whiteColor];
    return errorView;
}

- (void)fetchContextCodeWithPageName:(NSString *)pageName resultCallback:(KuiklyContextCodeCallback)callback {
    __unused NSString *unusedPageName = pageName;
    if (callback) {
        callback([KuiklyHostSupportConfiguration currentConfiguration].contextCode ?: @"Shared", nil);
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
