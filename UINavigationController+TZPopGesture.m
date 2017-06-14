//
//  UINavigationController+TZPopGesture.m
//  让UIScrollView的滑动和侧滑返回并存——Demo
//
//  Created by 谭真 on 2016/10/4.
//  Copyright © 2016年 谭真. All rights reserved.
//  2016.10.14 1.0.3版本

#import "UINavigationController+TZPopGesture.h"
#import <objc/runtime.h>

@interface UINavigationController (TZPopGesturePrivate)

@property (nonatomic, weak, readonly) id tz_naviDelegate;
@property (nonatomic, weak, readonly) id tz_popDelegate;


@end

@implementation UINavigationController (TZPopGesture)

static char *supportLeftBackKey = "supportLeftBackKey";
static char *navBgColorKey = "navBgColorKey";
static char *navBarClearKey = "navBarClearKey";
static char *navHairLineKey = "navHairLineKey";

+ (void)load {
    Method originalMethod = class_getInstanceMethod(self, @selector(viewWillAppear:));
    Method swizzledMethod = class_getInstanceMethod(self, @selector(tzPop_viewWillAppear:));
    method_exchangeImplementations(originalMethod, swizzledMethod);
    
}

- (void)tzPop_viewWillAppear:(BOOL)animated {
    [self tzPop_viewWillAppear:animated];
    // 只是为了触发tz_PopDelegate的get方法，获取到原始的interactivePopGestureRecognizer的delegate
    [self.tz_popDelegate class];
    // 获取导航栏的代理
    [self.tz_naviDelegate class];
    self.delegate = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.delegate = self.tz_naviDelegate;
    });
//    self.hh_supportLeftBack = YES;
}

- (void)setHh_supportLeftBack:(BOOL)hh_supportLeftBack{
    objc_setAssociatedObject(self, supportLeftBackKey, @(hh_supportLeftBack), OBJC_ASSOCIATION_ASSIGN);
    self.interactivePopGestureRecognizer.enabled = hh_supportLeftBack;
}

- (BOOL)hh_supportLeftBack{
    return [objc_getAssociatedObject(self, supportLeftBackKey) boolValue];
}

- (id)tz_popDelegate {
    id tz_popDelegate = objc_getAssociatedObject(self, _cmd);
    if (!tz_popDelegate) {
        tz_popDelegate = self.interactivePopGestureRecognizer.delegate;
        objc_setAssociatedObject(self, _cmd, tz_popDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tz_popDelegate;
}

- (id)tz_naviDelegate {
    id tz_naviDelegate = objc_getAssociatedObject(self, _cmd);
    if (!tz_naviDelegate) {
        tz_naviDelegate = self.delegate;
        if (tz_naviDelegate) {
            objc_setAssociatedObject(self, _cmd, tz_naviDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    return tz_naviDelegate;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
    if ([[self valueForKey:@"_isTransitioning"] boolValue]) {
        return NO;
    }
    if (self.childViewControllers.count <= 1 ||self.hh_supportLeftBack == NO) {
        return NO;
    }
    // 侧滑手势触发位置
    CGPoint location = [gestureRecognizer locationInView:self.view];
    CGPoint offSet = [gestureRecognizer translationInView:gestureRecognizer.view];
    BOOL ret = (0 < offSet.x && location.x <= 40);
    // NSLog(@"%@ %@",NSStringFromCGPoint(location),NSStringFromCGPoint(offSet));
    return ret;
}

/// 只有当系统侧滑手势失败了，才去触发ScrollView的滑动
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // 让系统的侧滑返回生效
//    self.interactivePopGestureRecognizer.enabled = YES;
    if (self.childViewControllers.count > 0) {
        if (viewController == self.childViewControllers[0]) {
            self.interactivePopGestureRecognizer.delegate = self.tz_popDelegate; // 不支持侧滑
        } else {
          
//             self.interactivePopGestureRecognizer.delegate = nil; // 支持侧滑
            if (self.hh_supportLeftBack == YES) {
                self.interactivePopGestureRecognizer.delegate = nil; // 支持侧滑
            }else{
                self.interactivePopGestureRecognizer.delegate = self.tz_popDelegate; // 不支持侧滑
            }
        }
    }
}

#pragma mark 透明度与颜色
- (void)setHh_navBgColor:(UIColor *)hh_navBgColor{
    objc_setAssociatedObject(self, navBgColorKey, hh_navBgColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)hh_navBgColor{
    return objc_getAssociatedObject(self, navBgColorKey);
}

- (UIImageView *)hh_navHairLine{
    UIImageView *hairLine = objc_getAssociatedObject(self, navHairLineKey);
    return hairLine;
}

- (void)setHh_navHairLine:(UIImageView *)hh_navHairLine{
   UIImageView *hairLine = [self findHairlineImageViewUnder:self.navigationBar];
    objc_setAssociatedObject(self, navHairLineKey, hairLine, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setHh_navBarClear:(BOOL)hh_navBarClear{
    [self willChangeValueForKey:@"hh_navBarClear"];
    objc_setAssociatedObject(self, navBarClearKey, @(hh_navBarClear), OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"hh_navBarClear"];
    
    [self hh_setNavBgAlpha:hh_navBarClear?0:1];
    self.hh_navHairLine.hidden = hh_navBarClear;
}

- (BOOL)hh_navBarClear{
    return [objc_getAssociatedObject(self, navBarClearKey) boolValue];
}

//TODO: 导航的线条
- (UIImageView *)findHairlineImageViewUnder:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findHairlineImageViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}


- (void)hh_setNavBgAlpha:(CGFloat)alpha{
    UIColor *color = self.hh_navBgColor?self.hh_navBgColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1];

    const CGFloat *components = CGColorGetComponents(color.CGColor);
//    color = [UIColor colorWithWhite:1 alpha:alpha];
    color = [UIColor colorWithRed:components[0] green:components[1] blue:components[2] alpha:alpha];
    [self.navigationBar setBackgroundImage:[self imageWithColor:color] forBarMetrics:UIBarMetricsDefault];
}

- (UIImage *)imageWithColor:(UIColor *)color{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [color setFill];
    CGContextFillRect(context, rect);
    UIImage *imgae = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imgae;
}

+ (void)initialize{
    if (self == [UINavigationController class]) {
        SEL originalSelector = NSSelectorFromString(@"_updateInteractiveTransition:");
        SEL swizzledSelector = NSSelectorFromString(@"hh_updateInteractiveTransition:");
        Method originalMethod = class_getInstanceMethod([self class], originalSelector);
        Method swizzledMethod = class_getInstanceMethod([self class], swizzledSelector);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

//交换的方法，监控滑动手势
- (void)hh_updateInteractiveTransition:(CGFloat)percentComplete{
    [self hh_updateInteractiveTransition:percentComplete];
    UIViewController *topVC = self.topViewController;
    if (topVC != nil) {
        id<UIViewControllerTransitionCoordinator> coor = topVC.transitionCoordinator;
        if (coor != nil) {
            //随着滑动的过程设置导航栏透明度渐变
            CGFloat fromAlpha = [coor viewControllerForKey:UITransitionContextFromViewControllerKey].hh_navBarBgAlpha;
            CGFloat toAlpha = [coor viewControllerForKey:UITransitionContextFromViewControllerKey].hh_navBarBgAlpha;
            CGFloat nowAlpha = fromAlpha + (double)(toAlpha-fromAlpha)*percentComplete;
            [self hh_setNavBgAlpha:nowAlpha];
        }
    }
}

- (void)dealInteractionChanges:(id<UIViewControllerTransitionCoordinatorContext>)context{
    if ([context isCancelled]) {//自动取消了返回手势
        NSTimeInterval cancleDuration = context.transitionDuration * context.percentComplete;
        [UIView animateWithDuration:cancleDuration animations:^{
            CGFloat nowAlpha = [context viewControllerForKey:UITransitionContextFromViewControllerKey].hh_navBarBgAlpha;
            [self hh_setNavBgAlpha:nowAlpha];
        }];
        
    }else{
        NSTimeInterval finishDuration = context.transitionDuration *(double)(1-context.percentComplete);
        [UIView animateWithDuration:finishDuration animations:^{
            CGFloat nowAlpha = [context viewControllerForKey:UITransitionContextToViewControllerKey].hh_navBarBgAlpha;
            [self hh_setNavBgAlpha:nowAlpha];
        }];
    }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    UIViewController *topVC = self.topViewController;
    if (topVC != nil) {
        id<UIViewControllerTransitionCoordinator> coor = topVC.transitionCoordinator;
        if (coor != nil) {
            if (HHiOS10) {
                [coor notifyWhenInteractionChangesUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                    [self dealInteractionChanges:context];
                }];
            }else{
                [coor notifyWhenInteractionEndsUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                    [self dealInteractionChanges:context];
                }];
            }
            
        }
    }
}

#pragma mark UINavigationBarDelegate
- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item{
    if (self.viewControllers.count >= navigationBar.items.count) {
        UIViewController *popToVC = self.viewControllers[self.viewControllers.count -1];
        [self hh_setNavBgAlpha:popToVC.hh_navBarBgAlpha];
    }
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item{
    [self hh_setNavBgAlpha:self.topViewController.hh_navBarBgAlpha];
}

@end



@interface UIViewController (TZPopGesturePrivate)
@property (nonatomic, strong) UIPanGestureRecognizer *tz_popGestureRecognizer;

@end

@implementation UIViewController (TZPopGesture)

static char *popGestureRecognizerKey = "popGestureRecognizerKey";
static char *navBarBgAlphaKey = "navBarBgAlphaKey";

- (void)setHh_navBarBgAlpha:(CGFloat)hh_navBarBgAlpha{
    objc_setAssociatedObject(self, navBarBgAlphaKey, @(hh_navBarBgAlpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (CGFloat)hh_navBarBgAlpha{
    return [objc_getAssociatedObject(self, navBarBgAlphaKey) floatValue];
}

- (void)tz_addPopGestureToView:(UIView *)view {
    if (!view) return;
    if (!self.navigationController) {
        // 在控制器转场的时候，self.navigationController可能是nil,这里用GCD和递归来处理这种情况
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self tz_addPopGestureToView:view];
        });
    } else {
        UIPanGestureRecognizer *pan = self.tz_popGestureRecognizer;
        if (![view.gestureRecognizers containsObject:pan]) {
            [view addGestureRecognizer:pan];
        }
    }
}



- (UIPanGestureRecognizer *)tz_popGestureRecognizer {
    UIPanGestureRecognizer *pan = objc_getAssociatedObject(self, popGestureRecognizerKey);
    if (!pan) {
        // 侧滑返回手势 手势触发的时候，让target执行action
        id target = self.navigationController.tz_popDelegate;
        SEL action = NSSelectorFromString(@"handleNavigationTransition:");
        pan = [[UIPanGestureRecognizer alloc] initWithTarget:target action:action];
        pan.maximumNumberOfTouches = 1;
        pan.delegate = self.navigationController;
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        objc_setAssociatedObject(self, popGestureRecognizerKey, pan, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return pan;
}

@end




