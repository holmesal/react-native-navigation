#import "RCCFooter.h"
#import "RCCManager.h"
#import <React/RCTRootView.h>
#import <React/RCTRootViewDelegate.h>
#import <React/RCTConvert.h>
#import "RCTHelpers.h"
#import <objc/runtime.h>

const NSInteger kFooterTag = 0x101010;

@interface RCCFooterView : UIView
@property (nonatomic, strong) RCTRootView *reactView;
@property (nonatomic, strong) UIVisualEffectView *visualEffectView;
@property (nonatomic, strong) UIView *overlayColorView;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic)         BOOL yellowBoxRemoved;
@end

@implementation RCCFooterView

-(instancetype)initWithFrame:(CGRect)frame params:(NSDictionary*)params
{
    self = [super initWithFrame:frame];
    if (self)
    {
//        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.params = params;
        self.yellowBoxRemoved = NO;
        
        NSDictionary *passProps = self.params[@"passProps"];
        
        NSDictionary *style = self.params[@"style"];
//        if (self.params != nil && style != nil)
//        {
//            
//            if (style[@"backgroundBlur"] != nil && ![style[@"backgroundBlur"] isEqualToString:@"none"])
//            {
//                self.visualEffectView = [[UIVisualEffectView alloc] init];
//                self.visualEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//                self.visualEffectView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
//                [self addSubview:self.visualEffectView];
//            }
//            
//            if (style[@"backgroundColor"] != nil)
//            {
//                UIColor *backgroundColor = [RCTConvert UIColor:style[@"backgroundColor"]];
//                if (backgroundColor != nil)
//                {
//                    self.overlayColorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
//                    self.overlayColorView.backgroundColor = backgroundColor;
//                    self.overlayColorView.alpha = 0;
//                    [self addSubview:self.overlayColorView];
//                }
//            }
//        }
        
        self.reactView = [[RCTRootView alloc] initWithBridge:[[RCCManager sharedInstance] getBridge] moduleName:self.params[@"component"] initialProperties:passProps];
//        self.reactView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.reactView.backgroundColor = [UIColor clearColor];
        self.reactView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        self.reactView.contentView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
//        self.reactView.sizeFlexibility = RCTRootViewSizeFlexibilityWidthAndHeight;
//        self.reactView.center = self.center;
        [self addSubview:self.reactView];
        
        [self.reactView.contentView.layer addObserver:self forKeyPath:@"frame" options:0 context:nil];
        [self.reactView.contentView.layer addObserver:self forKeyPath:@"bounds" options:0 context:NULL];
        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRNReload) name:RCTReloadNotification object:nil];
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    if(!self.yellowBoxRemoved)
    {
        self.yellowBoxRemoved = [RCTHelpers removeYellowBox:self.reactView];
    }
}

-(void)removeAllObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.reactView.contentView.layer removeObserver:self forKeyPath:@"frame" context:nil];
    [self.reactView.contentView.layer removeObserver:self forKeyPath:@"bounds" context:NULL];
}

-(void)dealloc
{
    [self removeAllObservers];
}

-(void)onRNReload
{
    [self removeAllObservers];
    [self removeFromSuperview];
    self.reactView = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    CGSize selfSize = self.frame.size;
    CGSize frameSize = CGSizeZero;
    if ([object isKindOfClass:[CALayer class]])
        frameSize = ((CALayer*)object).frame.size;
    if ([object isKindOfClass:[UIView class]])
        frameSize = ((UIView*)object).frame.size;
    
//    self.reactView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
//    self.reactView.contentView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
//    if (!CGSizeEqualToSize(frameSize, self.reactView.frame.size))
//    {
//        self.reactView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
//        self.reactView.contentView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
//        //        self.reactView.frame = CGRectMake((self.frame.size.width - frameSize.width) * 0.5, (self.frame.size.height - frameSize.height) * 0.5, frameSize.width, frameSize.height);
//    }
}

-(UIBlurEffect*)blurEfectForCurrentStyle
{
    NSDictionary *style = self.params[@"style"];
    NSString *backgroundBlur = style[@"backgroundBlur"];
    if ([backgroundBlur isEqualToString:@"none"])
    {
        return nil;
    }
    
    UIBlurEffectStyle blurEffectStyle = UIBlurEffectStyleDark;
    if ([backgroundBlur isEqualToString:@"light"])
        blurEffectStyle = UIBlurEffectStyleLight;
    else if ([backgroundBlur isEqualToString:@"xlight"])
        blurEffectStyle = UIBlurEffectStyleExtraLight;
    else if ([backgroundBlur isEqualToString:@"dark"])
        blurEffectStyle = UIBlurEffectStyleDark;
    return [UIBlurEffect effectWithStyle:blurEffectStyle];
}

-(void)showAnimated
{
    NSDictionary *style = self.params[@"style"];
    NSNumber *styleHeight = style[@"height"];
    CGFloat height = [styleHeight floatValue];
//    if (self.visualEffectView != nil || self.overlayColorView != nil)
//    {
//        [UIView animateWithDuration:0.3 animations:^()
//         {
//             if (self.visualEffectView != nil)
//             {
//                 self.visualEffectView.effect = [self blurEfectForCurrentStyle];
//             }
//             
//             if (self.overlayColorView != nil)
//             {
//                 self.overlayColorView.alpha = 1;
//             }
//         }];
//    }
    
    self.reactView.transform = CGAffineTransformMakeTranslation(0, height);
    //self.reactView.alpha = 0.5f;
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^()
     {
         self.reactView.transform = CGAffineTransformIdentity;
//         self.reactView.alpha = 1;
     } completion:nil];
}

-(void)dismissAnimated
{
    NSDictionary *style = self.params[@"style"];
    NSNumber *styleHeight = style[@"height"];
    CGFloat height = [styleHeight floatValue];
    BOOL hasOverlayViews = (self.visualEffectView != nil || self.overlayColorView != nil);
    
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^()
     {
         self.reactView.transform = CGAffineTransformMakeTranslation(0, height);
//         self.reactView.alpha = 0;
     }
                     completion:^(BOOL finished)
     {
         if (!hasOverlayViews)
         {
             [self removeFromSuperview];
         }
     }];
    
//    if (hasOverlayViews)
//    {
//        [UIView animateWithDuration:0.25 delay:0.15 options:UIViewAnimationOptionCurveEaseOut animations:^()
//         {
//             if (self.visualEffectView != nil)
//             {
//                 self.visualEffectView.effect = nil;
//             }
//             
//             if (self.overlayColorView != nil)
//             {
//                 self.overlayColorView.alpha = 0;
//             }
//             
//         } completion:^(BOOL finished)
//         {
//             [self removeFromSuperview];
//         }];
//    }
}

@end

@implementation RCCFooter

+(UIWindow*)getWindow
{
    UIApplication *app = [UIApplication sharedApplication];
    UIWindow *window = (app.keyWindow != nil) ? app.keyWindow : app.windows[0];
    return window;
}

+(void)showWithParams:(NSDictionary*)params
{
    UIWindow *window = [RCCFooter getWindow];
    if ([window viewWithTag:kFooterTag] != nil)
    {
        return;
    }
    
    NSDictionary *style = params[@"style"];
    NSNumber *styleHeight = style[@"height"];
    CGFloat height = [styleHeight floatValue];
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
//    RCCFooterView *footer = [[RCCFooterView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) params:params];
    RCCFooterView *footer = [[RCCFooterView alloc] initWithFrame:CGRectMake(0, screenHeight - height, [UIScreen mainScreen].bounds.size.width, height) params:params];
    footer.tag = kFooterTag;
    [window addSubview:footer];
    [footer showAnimated];
}

+(void)dismiss
{
    UIWindow *window = [RCCFooter getWindow];
    RCCFooterView *footer = [window viewWithTag:kFooterTag];
    if (footer != nil)
    {
        [footer dismissAnimated];
    }
}

@end
