//
//  UINavigationController+TZPop.h
//  让UIScrollView的滑动和侧滑返回并存——Demo
//
//  Created by 谭真 on 2016/10/4.
//  Copyright © 2016年 谭真. All rights reserved.
//  2016.10.14 1.0.3版本

#import <UIKit/UIKit.h>

@interface UINavigationController (TZPopGesture)<UIGestureRecognizerDelegate,UINavigationControllerDelegate,UINavigationBarDelegate>

@property (nonatomic, assign) BOOL hh_supportLeftBack;//Han新增
@property (nonatomic, strong) UIColor *hh_navBgColor;
@property (nonatomic, assign) BOOL hh_navBarClear;
@property (nonatomic, strong) UIImageView *hh_navHairLine;

- (void)hh_setNavBgAlpha:(CGFloat)alpha;
- (UIImage *)imageWithColor:(UIColor *)color;

@end


@interface UIViewController (TZPopGesture)

@property (assign, nonatomic) CGFloat hh_navBarBgAlpha;

- (void)tz_addPopGestureToView:(UIView *)view;


@end

