/*
 * Tencent is pleased to support the open source community by making KuiklyUI
 * available.
 * Copyright (C) 2025 Tencent. All rights reserved.
 * Licensed under the License of KuiklyUI;
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * https://github.com/Tencent-TDS/KuiklyUI/blob/main/LICENSE
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#import "../../Protocol/KuiklyRenderModuleExportProtocol.h"
#import "../../Protocol/KRUIKit.h" // [macOS]
#import "../Category/NSObject+KR.h"
#import "../../View/KuiklyRenderView.h"
#import "../../TDFCommon/TDFBaseModule.h"
NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const KR_PARAM_KEY;
FOUNDATION_EXTERN NSString *const KR_CALLBACK_KEY;

@interface KRBaseModule : TDFBaseModule<KuiklyRenderModuleExportProtocol>

/*
 * @brief 获取kotlin侧tag(nativeRef)对应的Native View实例（仅支持在主线程调用）.
 * @param tag view对应的索引
 * @return view实例
 */
- (UIView * _Nullable)viewWithTag:(NSNumber *)tag;

@end

NS_ASSUME_NONNULL_END
