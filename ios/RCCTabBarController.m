#import "RCCTabBarController.h"
#import "RCCViewController.h"
#import <React/RCTConvert.h>
#import "RCCManager.h"
#import "RCTHelpers.h"
#import <React/RCTUIManager.h>
#import "UIViewController+Rotation.h"

@interface RCTUIManager ()

- (void)configureNextLayoutAnimation:(NSDictionary *)config
                        withCallback:(RCTResponseSenderBlock)callback
                       errorCallback:(__unused RCTResponseSenderBlock)errorCallback;

@end

@interface RCCTabBarController ()

@property (nonatomic)         BOOL movedState;

@end

@implementation RCCTabBarController


-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return [self supportedControllerOrientations];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
  id queue = [[RCCManager sharedInstance].getBridge uiManager].methodQueue;
  dispatch_async(queue, ^{
    [[[RCCManager sharedInstance].getBridge uiManager] configureNextLayoutAnimation:nil withCallback:^(NSArray* arr){} errorCallback:^(NSArray* arr){}];
  });
  
  if (tabBarController.selectedIndex != [tabBarController.viewControllers indexOfObject:viewController]) {
    [RCCTabBarController sendScreenTabChangedEvent:viewController];
  }

  return YES;
}

- (UIImage *)image:(UIImage*)image withColor:(UIColor *)color1
{
  UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextTranslateCTM(context, 0, image.size.height);
  CGContextScaleCTM(context, 1.0, -1.0);
  CGContextSetBlendMode(context, kCGBlendModeNormal);
  CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
  CGContextClipToMask(context, rect, image.CGImage);
  [color1 setFill];
  CGContextFillRect(context, rect);
  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newImage;
}

- (instancetype)initWithProps:(NSDictionary *)props children:(NSArray *)children globalProps:(NSDictionary*)globalProps bridge:(RCTBridge *)bridge
{
  self = [super init];
  if (!self) return nil;

  self.delegate = self;
  
  self.movedState = false;

  self.tabBar.translucent = YES; // default

  UIColor *buttonColor = nil;
  UIColor *selectedButtonColor = nil;
  NSDictionary *tabsStyle = props[@"style"];
  if (tabsStyle)
  {
    NSString *tabBarButtonColor = tabsStyle[@"tabBarButtonColor"];
    if (tabBarButtonColor)
    {
      UIColor *color = tabBarButtonColor != (id)[NSNull null] ? [RCTConvert UIColor:tabBarButtonColor] : nil;
      self.tabBar.tintColor = color;
      buttonColor = color;
      selectedButtonColor = color;
    }

    NSString *tabBarSelectedButtonColor = tabsStyle[@"tabBarSelectedButtonColor"];
    if (tabBarSelectedButtonColor)
    {
      UIColor *color = tabBarSelectedButtonColor != (id)[NSNull null] ? [RCTConvert UIColor:tabBarSelectedButtonColor] : nil;
      self.tabBar.tintColor = color;
      selectedButtonColor = color;
    }

    NSString *tabBarBackgroundColor = tabsStyle[@"tabBarBackgroundColor"];
    if (tabBarBackgroundColor)
    {
      UIColor *color = tabBarBackgroundColor != (id)[NSNull null] ? [RCTConvert UIColor:tabBarBackgroundColor] : nil;
      self.tabBar.barTintColor = color;
    }
  }

  NSMutableArray *viewControllers = [NSMutableArray array];

  // go over all the tab bar items
  for (NSDictionary *tabItemLayout in children)
  {
    // make sure the layout is valid
    if (![tabItemLayout[@"type"] isEqualToString:@"TabBarControllerIOS.Item"]) continue;
    if (!tabItemLayout[@"props"]) continue;

    // get the view controller inside
    if (!tabItemLayout[@"children"]) continue;
    if (![tabItemLayout[@"children"] isKindOfClass:[NSArray class]]) continue;
    if ([tabItemLayout[@"children"] count] < 1) continue;
    NSDictionary *childLayout = tabItemLayout[@"children"][0];
    UIViewController *viewController = [RCCViewController controllerWithLayout:childLayout globalProps:globalProps bridge:bridge];
    if (!viewController) continue;

    // create the tab icon and title
    NSString *title = tabItemLayout[@"props"][@"title"];
    UIImage *iconImage = nil;
    id icon = tabItemLayout[@"props"][@"icon"];
    if (icon)
    {
      iconImage = [RCTConvert UIImage:icon];
      if (buttonColor)
      {
        iconImage = [[self image:iconImage withColor:buttonColor] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
      }
    }
    UIImage *iconImageSelected = nil;
    id selectedIcon = tabItemLayout[@"props"][@"selectedIcon"];
    if (selectedIcon) {
      iconImageSelected = [RCTConvert UIImage:selectedIcon];
    } else {
      iconImageSelected = [RCTConvert UIImage:icon];
    }

    viewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:iconImage tag:0];
    viewController.tabBarItem.accessibilityIdentifier = tabItemLayout[@"props"][@"testID"];
    viewController.tabBarItem.selectedImage = iconImageSelected;
    
    NSMutableDictionary *unselectedAttributes = [RCTHelpers textAttributesFromDictionary:tabsStyle withPrefix:@"tabBarText" baseFont:[UIFont fontWithName:@"AmericanTypewriter" size:20.0f]];
    if (!unselectedAttributes[NSForegroundColorAttributeName] && buttonColor) {
      unselectedAttributes[NSForegroundColorAttributeName] = buttonColor;
    }
    
    [unselectedAttributes setValue:[UIFont fontWithName:@"StyreneBApp-Regular" size:11] forKey:NSFontAttributeName];
    
    [viewController.tabBarItem setTitleTextAttributes:unselectedAttributes forState:UIControlStateNormal]
    ;
    
    NSMutableDictionary *selectedAttributes = [RCTHelpers textAttributesFromDictionary:tabsStyle withPrefix:@"tabBarSelectedText" baseFont:[UIFont systemFontOfSize:10]];
    if (!selectedAttributes[NSForegroundColorAttributeName] && selectedButtonColor) {
      selectedAttributes[NSForegroundColorAttributeName] = selectedButtonColor;
    }
    
    [selectedAttributes setValue:[UIFont fontWithName:@"StyreneBApp-Regular" size:11] forKey:NSFontAttributeName];
    
    [viewController.tabBarItem setTitleTextAttributes:selectedAttributes forState:UIControlStateSelected];
    // create badge
    NSObject *badge = tabItemLayout[@"props"][@"badge"];
    if (badge == nil || [badge isEqual:[NSNull null]])
    {
      viewController.tabBarItem.badgeValue = nil;
    }
    else
    {
      viewController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%@", badge];
    }
    
//    [viewController.tabBarItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"StyreneBApp-Regular" size:11]} forState:UIControlStateNormal];
    
    [viewController.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0.0f, -9.0f)];
    
    [viewController.tabBarItem setImageInsets:UIEdgeInsetsMake(4.0f, 0, -4.0f, 0)];
    
    [self.tabBarController.tabBar.layer setBorderWidth:1.0f];
    [self.tabBarController.tabBar.layer setBorderColor:[UIColor colorWithRed:0.77 green:0.77 blue:0.77 alpha:1.0].CGColor];

    [viewControllers addObject:viewController];
  }

  // replace the tabs
  self.viewControllers = viewControllers;
  
  [self setRotation:props];
  
  // Initial frame
  self.tabBar.frame = [self getFrameForMovedState:NO];

  return self;
}

- (void)performAction:(NSString*)performAction actionParams:(NSDictionary*)actionParams bridge:(RCTBridge *)bridge completion:(void (^)(void))completion
{
  if ([performAction isEqualToString:@"setBadge"])
  {
    UIViewController *viewController = nil;
    NSNumber *tabIndex = actionParams[@"tabIndex"];
    if (tabIndex)
    {
      int i = (int)[tabIndex integerValue];

      if ([self.viewControllers count] > i)
      {
        viewController = [self.viewControllers objectAtIndex:i];
      }
    }
    NSString *contentId = actionParams[@"contentId"];
    NSString *contentType = actionParams[@"contentType"];
    if (contentId && contentType)
    {
      viewController = [[RCCManager sharedInstance] getControllerWithId:contentId componentType:contentType];
    }

    if (viewController)
    {
      NSObject *badge = actionParams[@"badge"];

      if (badge == nil || [badge isEqual:[NSNull null]])
      {
        viewController.tabBarItem.badgeValue = nil;
      }
      else
      {
        viewController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%@", badge];
      }
    }
  }

  if ([performAction isEqualToString:@"switchTo"])
  {
    UIViewController *viewController = nil;
    NSNumber *tabIndex = actionParams[@"tabIndex"];
    if (tabIndex)
    {
      int i = (int)[tabIndex integerValue];

      if ([self.viewControllers count] > i)
      {
        viewController = [self.viewControllers objectAtIndex:i];
      }
    }
    NSString *contentId = actionParams[@"contentId"];
    NSString *contentType = actionParams[@"contentType"];
    if (contentId && contentType)
    {
      viewController = [[RCCManager sharedInstance] getControllerWithId:contentId componentType:contentType];
    }

    if (viewController)
    {
      [self setSelectedViewController:viewController];
    }
  }
  
  if ([performAction isEqualToString:@"setFooterHidden"])
  {
    BOOL hidden = [actionParams[@"hidden"] boolValue];
    self.movedState = !hidden;
    NSLog(@"tabBar setFooterHidden: %s", hidden ? "true" : "false");
    NSLog(@"tabBar frame (pre-animation): x: %f, y: %f, width: %f, height: %f", self.tabBar.frame.origin.x, self.tabBar.frame.origin.y, self.tabBar.frame.size.width, self.tabBar.frame.size.height);
    
    // Do the animation
    [UIView animateWithDuration: 0.4
                          delay: 0
         usingSpringWithDamping: 0.8
          initialSpringVelocity: 0
                        options: (hidden ? UIViewAnimationOptionCurveEaseIn : UIViewAnimationOptionCurveEaseOut)
                     animations:^()
     {
       CGRect toFrame = [self getFrameForMovedState:!hidden];
       NSLog(@"tabBar toFrame (target frame): x: %f, y: %f, width: %f, height: %f", toFrame.origin.x, toFrame.origin.y, toFrame.size.width, toFrame.size.height);

//       CGFloat tabBarHeight = self.tabBar.frame.size.height;
//       float offset = hidden ? 0 : -[actionParams[@"height"] floatValue];
       self.tabBar.frame = toFrame;
       NSLog(@"tabBar frame (during animation): x: %f, y: %f, width: %f, height: %f", self.tabBar.frame.origin.x, self.tabBar.frame.origin.y, self.tabBar.frame.size.width, self.tabBar.frame.size.height);
       
       
       
//       self.tabBar.transform = CGAffineTransformMakeTranslation(0, -70.0f);
//       NSLog(@"tabBar transform: tx: %f, ty: %f", self.tabBar.transform.tx, self.tabBar.transform.ty);
//       self.tabBar.transform = hidden ? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0, -70.0f);
     }
                     completion:^(BOOL finished)
     {
//       NSLog(@"(completed): tabBar transform: tx: %f, ty: %f", self.tabBar.transform.tx, self.tabBar.transform.ty);
       NSLog(@"tabBar frame (after animation): x: %f, y: %f, width: %f, height: %f", self.tabBar.frame.origin.x, self.tabBar.frame.origin.y, self.tabBar.frame.size.width, self.tabBar.frame.size.height);
       if (completion != nil)
       {
         completion();
       }
     }];
    return;
  }

  if ([performAction isEqualToString:@"setTabBarHidden"])
  {
    BOOL hidden = [actionParams[@"hidden"] boolValue];
    NSLog(@"tabBar setTabBarHidden: %s", hidden ? "true" : "false");
    [UIView animateWithDuration: ([actionParams[@"animated"] boolValue] ? 0.45 : 0)
                          delay: 0
         usingSpringWithDamping: 0.75
          initialSpringVelocity: 0
                        options: (hidden ? UIViewAnimationOptionCurveEaseIn : UIViewAnimationOptionCurveEaseOut)
                     animations:^()
     {
       self.tabBar.transform = hidden ? CGAffineTransformMakeTranslation(0, self.tabBar.frame.size.height) : CGAffineTransformIdentity;
     }
                     completion:^(BOOL finished)
     {
       if (completion != nil)
       {
         completion();
       }
     }];
    return;
  }
  else if (completion != nil)
  {
    completion();
  }
}

-(CGRect)getFrameForMovedState:(bool)isMoved {
  float screenHeight = [UIScreen mainScreen].bounds.size.height;
  NSLog(@"getFrameForMovedState screen dims: width: %f, height: %f", [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
  float tabHeight = 66.0f;
  float yDefault = screenHeight - tabHeight;
  float yMoved = yDefault - 48.0f;
  return CGRectMake(
                    0.0f,
                    isMoved ? yMoved : yDefault,
                    [UIScreen mainScreen].bounds.size.width,
                    tabHeight
                    );
}

+(void)sendScreenTabChangedEvent:(UIViewController*)viewController {
  if ([viewController.view isKindOfClass:[RCTRootView class]]){
    RCTRootView *rootView = (RCTRootView *)viewController.view;
    
    if (rootView.appProperties && rootView.appProperties[@"navigatorEventID"]) {
      NSString *navigatorID = rootView.appProperties[@"navigatorID"];
      NSString *screenInstanceID = rootView.appProperties[@"screenInstanceID"];
      
      [[[RCCManager sharedInstance] getBridge].eventDispatcher sendAppEventWithName:rootView.appProperties[@"navigatorEventID"] body:@
       {
         @"id": @"bottomTabSelected",
         @"navigatorID": navigatorID,
         @"screenInstanceID": screenInstanceID
       }];
    }
  }
  
  if ([viewController isKindOfClass:[UINavigationController class]]) {
    UINavigationController *navigationController = (UINavigationController*)viewController;
    UIViewController *topViewController = [navigationController topViewController];
    [RCCTabBarController sendScreenTabChangedEvent:topViewController];
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  // Make damn sure the frame is where it should be
  self.tabBar.frame = [self getFrameForMovedState:self.movedState];
}

- (void)viewWillLayoutSubviews {
  // If the height isn't set here every time shit breaks for some reason
  const CGFloat kBarHeight = 60;
  CGRect tabFrame = self.tabBar.frame;
  // do NOT set the Y here or it will fuck with the animation
  tabFrame.size.height = kBarHeight;
  tabFrame.size.width = [UIScreen mainScreen].bounds.size.width; // For some reason sometimes the width is 0
  tabFrame.origin.x = 0;
  self.tabBar.frame = tabFrame;
  
  NSLog(@"viewWillLayoutSubviews screen dims: width: %f, height: %f", [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
  
  // old stuffs:
//  tabFrame.origin.y = self.view.frame.size.height - kBarHeight;
//  self.tabFrame = tabFrame;
//  self.tabBar.frame = [self getFrameForMovedState:NO];
  NSLog(@"viewWillLayoutSubviews tabBar frame: x: %f, y: %f, width: %f, height: %f", self.tabFrame.origin.x, self.tabFrame.origin.y, self.tabFrame.size.width, self.tabFrame.size.height);
}


@end
