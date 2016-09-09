//
//  PBRevealViewController.m
//  PBRevealViewController
//
//  Created by Patrick BODET on 29/06/2016.
//  Copyright © 2016 iDevelopper. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PBRevealViewController.h"

#pragma mark - UIViewController(PBRevealViewController) Category

@implementation UIViewController(PBRevealViewController)

- (PBRevealViewController *)revealViewController
{
    UIViewController *parent = self;
    Class revealClass = [PBRevealViewController class];
    while ( nil != (parent = [parent parentViewController]) && ![parent isKindOfClass:revealClass] ) {}
    return (id)parent;
}

@end

#pragma mark - PBRevealViewControllerSegueSetController segue identifiers

NSString * const PBSegueLeftIdentifier =    @"pb_left";
NSString * const PBSegueMainIdentifier =    @"pb_main";
NSString * const PBSegueRightIdentifier =   @"pb_right";


#pragma mark - PBRevealViewControllerSegueSetController class

@implementation PBRevealViewControllerSegueSetController

- (void)perform
{
    NSString *identifier = self.identifier;
    PBRevealViewController *rvc = self.sourceViewController;
    UIViewController *dvc = self.destinationViewController;

    CGRect frame = dvc.view.frame;
    if ([[UIDevice currentDevice] systemVersion].floatValue < 7.0) {
        frame.origin.y = 0;
        if ([dvc isKindOfClass:[UINavigationController class]]) {
            BOOL statusBarIsHidden = ([UIApplication sharedApplication].statusBarFrame.size.height == 0.);
            if (!statusBarIsHidden) {
                frame.size.height -= [UIApplication sharedApplication].statusBarFrame.size.height;
            }
        }
        dvc.view.frame = frame;
    }
    if ([identifier isEqualToString:PBSegueMainIdentifier]) {
        [rvc addChildViewController:dvc];
        [dvc didMoveToParentViewController:rvc];
        rvc.mainViewController = dvc;
    }
    else if ([identifier isEqualToString:PBSegueLeftIdentifier]) {
        rvc.leftViewController = dvc;
    }
    else if ([identifier isEqualToString:PBSegueRightIdentifier]) {
        rvc.rightViewController = dvc;
    }
}

@end

#pragma mark - PBRevealViewControllerSeguePushController class

@implementation PBRevealViewControllerSeguePushController

- (void)perform
{
    PBRevealViewController *rvc = [self.sourceViewController revealViewController];
    UIViewController *dvc = self.destinationViewController;
    [rvc pushMainViewController:dvc animated:YES];
}

@end

#pragma mark - PBRevealViewControllerPanGestureRecognizer

#import <UIKit/UIGestureRecognizerSubclass.h>

@interface PBRevealViewControllerPanGestureRecognizer : UIPanGestureRecognizer
@end

@implementation PBRevealViewControllerPanGestureRecognizer
{
    BOOL    _dragging;
    CGPoint _beginPoint;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    _beginPoint = [touch locationInView:self.view];
    _dragging = NO;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    if ( _dragging || self.state == UIGestureRecognizerStateFailed) {
        return;
    }
    
    const CGFloat kDirectionPanThreshold = 5;
    
    UITouch *touch = [touches anyObject];
    CGPoint nowPoint = [touch locationInView:self.view];
    
    if (ABS(nowPoint.x - _beginPoint.x) > kDirectionPanThreshold) {
        _dragging = YES;
    }
    else if (ABS(nowPoint.y - _beginPoint.y) > kDirectionPanThreshold) {
        self.state = UIGestureRecognizerStateFailed;
    }
}

@end

#pragma mark - PBContextTransitioningObject

@interface PBContextTransitionObject : NSObject<UIViewControllerContextTransitioning>
@end

@implementation PBContextTransitionObject
{
    __weak PBRevealViewController *_revealController;
    UIView *_containerView;
    UIViewController *_toViewController;
    UIViewController *_fromViewController;
    void (^_completion)(void);
}


- (id)initWithRevealController:(PBRevealViewController*)revealController containerView:(UIView *)containerView fromViewController:(UIViewController *)fromViewController toViewController:(UIViewController*)toViewController completion:(void (^)(void))completion
{
    self = [super init];
    if ( self )
    {
        _revealController = revealController;
        _containerView = containerView;
        _fromViewController = fromViewController;
        _toViewController = toViewController;
        _completion = completion;
    }
    return self;
}

- (UIView *)containerView {
    return _containerView;
}

- (BOOL)isAnimated {
    return YES;
}

- (BOOL)isInteractive {
    return NO;  // not supported
}

- (BOOL)transitionWasCancelled {
    return NO; // not supported
}

- (CGAffineTransform)targetTransform {
    return CGAffineTransformIdentity;
}

- (UIModalPresentationStyle)presentationStyle {
    return UIModalPresentationNone;  // not applicable
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete {
    // not supported
}

- (void)pauseInteractiveTransition {
    // not supported
}

- (void)finishInteractiveTransition {
    // not supported
}

- (void)cancelInteractiveTransition {
    // not supported
}

- (void)completeTransition:(BOOL)didComplete {
    _completion();
}

- (UIViewController *)viewControllerForKey:(NSString *)key {
    if ( [key isEqualToString:UITransitionContextFromViewControllerKey] )
        return _fromViewController;
    
    if ( [key isEqualToString:UITransitionContextToViewControllerKey] )
        return _toViewController;
    
    return nil;
}

- (UIView *)viewForKey:(NSString *)key {
    return nil;
}

- (CGRect)initialFrameForViewController:(UIViewController *)vc {
    return vc.view.frame;
}

- (CGRect)finalFrameForViewController:(UIViewController *)vc {
    return vc.view.frame;
}

@end

#pragma mark - PBRevealView Class

@interface PBRevealView: UIView
{
    __weak PBRevealViewController *_revealController;
}
@end

@implementation PBRevealView

- (id)initWithFrame:(CGRect)frame controller:(PBRevealViewController*)revealController
{
    self = [super initWithFrame:frame];
    if ( self )
    {
        _revealController = revealController;
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL isInside = [super pointInside:point withEvent:event];
    if (isInside) {
        _revealController.tapGestureRecognizer.enabled = YES;
        
        if (_revealController.isLeftViewOpen && point.x < _revealController.leftViewRevealWidth) {
            _revealController.tapGestureRecognizer.enabled = NO;
        }
        if (_revealController.isRightViewOpen && point.x > (self.bounds.size.width - _revealController.rightViewRevealWidth)) {
            _revealController.tapGestureRecognizer.enabled = NO;
        }
        return YES;
    }
    return NO;
}

@end

#pragma mark - PBRevealViewController Class

@interface PBRevealViewController() <UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIView        *contentView;
@property (nonatomic) BOOL                  userInteractionStore;

@property (nonatomic) UINavigationBar       *navigationBar;

@property (nonatomic) UIVisualEffectView    *leftEffectView;
@property (nonatomic) UIVisualEffectView    *rightEffectView;


@end

@implementation PBRevealViewController

#pragma mark - Init

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if ( self )
    {
        [self initDefaultProperties];
    }
    return self;
}

- (id)initWithLeftViewController:(UIViewController *)leftViewController mainViewController:(UIViewController *)mainViewController rightViewController:(UIViewController *)rightViewController
{
    self = [super init];
    if ( self )
    {
        [self initDefaultProperties];
        
        if ([[UIDevice currentDevice] systemVersion].floatValue < 7.0) {
            BOOL statusBarIsHidden = ([UIApplication sharedApplication].statusBarFrame.size.height == 0.);
            CGRect frame = mainViewController.view.frame;
            frame.origin.y = 0;
            if ([mainViewController isKindOfClass:[UINavigationController class]]) {
                if (!statusBarIsHidden) {
                    frame.size.height -= [UIApplication sharedApplication].statusBarFrame.size.height;
                }
            }
            mainViewController.view.frame = frame;
            if (leftViewController) {
                frame = leftViewController.view.frame;
                frame.origin.y = 0;
                if ([leftViewController isKindOfClass:[UINavigationController class]]) {
                    if (!statusBarIsHidden) {
                        frame.size.height -= [UIApplication sharedApplication].statusBarFrame.size.height;
                    }
                }
                leftViewController.view.frame = frame;
            }
            if (rightViewController) {
                frame = rightViewController.view.frame;
                frame.origin.y = 0;
                if ([rightViewController isKindOfClass:[UINavigationController class]]) {
                    if (!statusBarIsHidden) {
                        frame.size.height -= [UIApplication sharedApplication].statusBarFrame.size.height;
                    }
                }
                rightViewController.view.frame = frame;
            }
        }
        [self addChildViewController:mainViewController];
        [_mainViewController didMoveToParentViewController:self];
        _mainViewController = mainViewController;

        _leftViewController = leftViewController;
        _rightViewController = rightViewController;
        
        [self reloadLeftShadow];
        [self reloadRightShadow];
        [self reloadMainShadow];
    }
    return self;
}

- (void)initDefaultProperties
{
    self.navigationBar = [[UINavigationBar alloc]init];
    
    _mainViewShadowRadius = 5.0f;
    _mainViewShadowOffset = CGSizeMake(0.0f, 5.0f);
    _mainViewShadowOpacity = 1.0f;
    _mainViewShadowColor = [UIColor blackColor];
    
    _leftPresentViewHierarchically = NO;

    _leftPresentViewOnTop = YES;
    _leftViewRevealDisplacement = 40.0f;
    
    _leftViewRevealWidth = 260.0f;
    _leftToggleAnimationDuration = 0.5f;
    _leftToggleSpringDampingRatio = 0.8f;
    _leftToggleSpringVelocity = 0.5f;
    _leftViewShadowRadius = 5.0f;
    _leftViewShadowOffset = CGSizeMake(0.0f, 5.0f);
    _leftViewShadowOpacity = 1.0f;
    _leftViewShadowColor = [UIColor blackColor];
    
    _leftViewBlurEffectStyle = PBRevealBlurEffectStyleNone;

    
    _rightPresentViewHierarchically = NO;

    _rightPresentViewOnTop = YES;
    _rightViewRevealDisplacement = 40.0f;
    
    _rightViewRevealWidth = 160.0f;
    _rightToggleAnimationDuration = 0.5f;
    _rightToggleSpringDampingRatio = 0.8f;
    _rightToggleSpringVelocity = 0.5f;
    _rightViewShadowRadius = 5.0f;
    _rightViewShadowOffset = CGSizeMake(0.0f, 5.0f);
    _rightViewShadowOpacity = 1.0f;
    _rightViewShadowColor = [UIColor blackColor];
    
    _rightViewBlurEffectStyle = PBRevealBlurEffectStyleNone;

    _replaceViewAnimationDuration = 0.25f;
    
    _swipeVelocity = 250.0f;
    _toggleAnimationType = PBRevealToggleAnimationTypeNone;
    
    _leftViewRevealOverdraw = 60.0f;
    _rightViewRevealOverdraw = 60.0f;
    
    _isLeftViewOpen = NO;
    _isLeftViewDragging = NO;
    
    _isRightViewOpen = NO;
    _isRightViewDragging = NO;
    
    _userInteractionStore = YES;
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    [self loadStoryboardControllers];
    
    CGRect frame = [[UIScreen mainScreen] bounds];
    if ([[UIDevice currentDevice] systemVersion].floatValue < 7.0) {
        BOOL statusBarIsHidden = ([UIApplication sharedApplication].statusBarFrame.size.height == 0.);
        if (!statusBarIsHidden) {
            frame.size.height -= [UIApplication sharedApplication].statusBarFrame.size.height;
        }
    }

    self.contentView = [[PBRevealView alloc] initWithFrame:frame controller:self];
    
    [_contentView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    
    self.view = _contentView;
    [_contentView addSubview:_mainViewController.view];
    
    [self tapGestureRecognizer];
    [self panGestureRecognizer];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _userInteractionStore = _contentView.userInteractionEnabled;
}

// Load any defined Main/Left/Right controllers from the storyboard
- (void)loadStoryboardControllers
{
    if (self.storyboard && _leftViewController == nil)
    {
        //Try each segue separately so it doesn't break prematurely if either Rear or Right views are not used.
        @try
        {
            [self performSegueWithIdentifier:PBSegueLeftIdentifier sender:nil];
        }
        @catch(NSException *exception) {}
        
        @try
        {
            [self performSegueWithIdentifier:PBSegueRightIdentifier sender:nil];
        }
        @catch(NSException *exception) {}
        
        @try
        {
            [self performSegueWithIdentifier:PBSegueMainIdentifier sender:nil];
        }
        @catch(NSException *exception) {}
    }
}

#pragma mark - Public methods and property accessors

- (void)setLeftPresentViewHierarchically:(BOOL)leftPresentViewHierarchically
{
    _leftPresentViewHierarchically = leftPresentViewHierarchically;
    if (_leftPresentViewHierarchically) {
        CGRect frame = [self adjustsFrameForController:_leftViewController];
        _leftViewController.view.frame = frame;
    }
}

- (void)setRightPresentViewHierarchically:(BOOL)rightPresentViewHierarchically
{
    _rightPresentViewHierarchically = rightPresentViewHierarchically;
    if (_rightPresentViewHierarchically) {
        CGRect frame = [self adjustsFrameForController:_rightViewController];
        _rightViewController.view.frame = frame;
    }
}

- (void)setLeftViewRevealWidth:(CGFloat)leftViewRevealWidth
{
    if (_leftViewRevealWidth != leftViewRevealWidth) {
        _leftViewRevealWidth = leftViewRevealWidth;
        if (_isLeftViewOpen) {
            CGRect frame = _leftViewController.view.frame;
            frame.origin.x = 0.;
            frame.size.width = _leftViewRevealWidth;
            _leftViewController.view.frame = frame;
            if (!_leftPresentViewOnTop) {
                frame = _mainViewController.view.frame;
                frame.origin.x = _leftViewRevealWidth;
                _mainViewController.view.frame = frame;
            }
        }
    }
}

- (void)setLeftViewRevealWidth:(CGFloat)leftViewRevealWidth animated:(BOOL)animated
{
    NSTimeInterval duration = animated ? _leftToggleAnimationDuration : 0.0;
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 7.0) {
        [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:_leftToggleSpringDampingRatio initialSpringVelocity:_leftToggleSpringVelocity options:UIViewAnimationOptionLayoutSubviews animations:^{
            [self setLeftViewRevealWidth:leftViewRevealWidth];
        } completion:^(BOOL finished) {
        }];
    }
    else {
        [UIView animateWithDuration:duration animations:^{
            [self setLeftViewRevealWidth:leftViewRevealWidth];
        }];
    }
}

- (void)setRightViewRevealWidth:(CGFloat)rightViewRevealWidth
{
    if (_rightViewRevealWidth != rightViewRevealWidth) {
        _rightViewRevealWidth = rightViewRevealWidth;
        if (_isRightViewOpen) {
            CGRect frame = _rightViewController.view.frame;
            frame.origin.x = self.view.bounds.size.width - _rightViewRevealWidth;
            frame.size.width = _rightViewRevealWidth;
            _rightViewController.view.frame = frame;
            if (!_rightPresentViewOnTop) {
                frame = _mainViewController.view.frame;
                frame.origin.x = -(_rightViewRevealWidth);
                _mainViewController.view.frame = frame;
            }
        }
    }
}

- (void)setRightViewRevealWidth:(CGFloat)rightViewRevealWidth animated:(BOOL)animated
{
    NSTimeInterval duration = animated ? _rightToggleAnimationDuration : 0.0;
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 7.0) {
        [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:_rightToggleSpringDampingRatio initialSpringVelocity:_rightToggleSpringVelocity options:UIViewAnimationOptionLayoutSubviews animations:^{
            [self setRightViewRevealWidth:rightViewRevealWidth];
        } completion:^(BOOL finished) {
        }];
    }
    else {
        [UIView animateWithDuration:duration animations:^{
            [self setRightViewRevealWidth:rightViewRevealWidth];
        }];
    }
}

- (void)setMainViewShadowRadius:(CGFloat)mainViewShadowRadius
{
    _mainViewShadowRadius = mainViewShadowRadius;
    [self reloadMainShadow];
}

- (void)setMainViewShadowOffset:(CGSize)mainViewShadowOffset
{
    _mainViewShadowOffset = mainViewShadowOffset;
    [self reloadMainShadow];
}

- (void)setMainViewShadowOpacity:(CGFloat)mainViewShadowOpacity
{
    _mainViewShadowOpacity = mainViewShadowOpacity;
    [self reloadMainShadow];
}

- (void)setMainViewShadowColor:(UIColor *)mainViewShadowColor
{
    _mainViewShadowColor = mainViewShadowColor;
    [self reloadMainShadow];
}

- (void)reloadMainShadow
{
    CALayer *layer = _mainViewController.view.layer;
    layer.masksToBounds = NO;
    layer.shadowColor = _mainViewShadowColor.CGColor;
    layer.shadowOpacity = _mainViewShadowOpacity;
    layer.shadowOffset = _mainViewShadowOffset;
    layer.shadowRadius = _mainViewShadowRadius;
}

- (void)setLeftViewShadowRadius:(CGFloat)leftViewShadowRadius
{
    _leftViewShadowRadius = leftViewShadowRadius;
    [self reloadLeftShadow];
}

- (void)setLeftViewShadowOffset:(CGSize)leftViewShadowOffset
{
    _leftViewShadowOffset = leftViewShadowOffset;
    [self reloadLeftShadow];
}

- (void)setLeftViewShadowOpacity:(CGFloat)leftViewShadowOpacity
{
    _leftViewShadowOpacity = leftViewShadowOpacity;
    [self reloadLeftShadow];
}

- (void)setLeftViewShadowColor:(UIColor *)leftViewShadowColor
{
    _leftViewShadowColor = leftViewShadowColor;
    [self reloadLeftShadow];
}

- (void)reloadLeftShadow
{
    CALayer *layer = _leftViewController.view.layer;
    layer.masksToBounds = NO;
    layer.shadowColor = _leftViewShadowColor.CGColor;
    layer.shadowOpacity = _leftViewShadowOpacity;
    layer.shadowOffset = _leftViewShadowOffset;
    layer.shadowRadius = _leftViewShadowRadius;
}

- (void)setLeftViewBlurEffectStyle:(PBRevealBlurEffectStyle)leftViewBlurEffectStyle
{
    _leftViewBlurEffectStyle = leftViewBlurEffectStyle;
    [self reloadSideBlurEffectStyle:_leftViewBlurEffectStyle forController:_leftViewController forOperation:PBRevealControllerOperationReplaceLeftController];
}

- (void)setRightViewShadowRadius:(CGFloat)rightViewShadowRadius
{
    _rightViewShadowRadius = rightViewShadowRadius;
    [self reloadRightShadow];
}

- (void)setRightViewShadowOffset:(CGSize)rightViewShadowOffset
{
    _rightViewShadowOffset = rightViewShadowOffset;
    [self reloadRightShadow];
}

- (void)setRightViewShadowOpacity:(CGFloat)rightViewShadowOpacity
{
    _rightViewShadowOpacity = rightViewShadowOpacity;
    [self reloadRightShadow];
}

- (void)setRightViewShadowColor:(UIColor *)rightViewShadowColor
{
    _rightViewShadowColor = rightViewShadowColor;
    [self reloadRightShadow];
}

- (void)reloadRightShadow
{
    CALayer *layer = _rightViewController.view.layer;
    layer.masksToBounds = NO;
    layer.shadowColor = _rightViewShadowColor.CGColor;
    layer.shadowOpacity = _rightViewShadowOpacity;
    layer.shadowOffset = _rightViewShadowOffset;
    layer.shadowRadius = _rightViewShadowRadius;
}

- (void)setRightViewBlurEffectStyle:(PBRevealBlurEffectStyle)rightViewBlurEffectStyle
{
    _rightViewBlurEffectStyle = rightViewBlurEffectStyle;
    [self reloadSideBlurEffectStyle:_rightViewBlurEffectStyle forController:_rightViewController forOperation:PBRevealControllerOperationReplaceRightController];
}

- (void)reloadSideBlurEffectStyle:(PBRevealBlurEffectStyle)style forController:(UIViewController *)sideViewController forOperation:(PBRevealControllerOperation)operation
{
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0) {
        UITableView *tableView;
        
        if ([sideViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nc = (UINavigationController *)sideViewController;
            tableView = [self tableViewInView:nc.topViewController.view];
        }
        else {
            tableView = [self tableViewInView:sideViewController.view];
        }
        if (style != PBRevealBlurEffectStyleNone) {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:(UIBlurEffectStyle)style];
            UIVisualEffectView *sideEffectView = [[UIVisualEffectView alloc]initWithEffect:blurEffect];
            sideEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            UIVibrancyEffect *vibancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
            
            switch (operation) {
                case PBRevealControllerOperationReplaceLeftController:
                    [_leftEffectView removeFromSuperview];
                    self.leftEffectView = sideEffectView;
                    break;
                    
                case PBRevealControllerOperationReplaceRightController:
                    [_rightEffectView removeFromSuperview];
                    self.rightEffectView = sideEffectView;
                    break;
                    
                default:
                    break;
            }
            if (tableView) {
                switch (operation) {
                    case PBRevealControllerOperationReplaceLeftController:
                        _leftEffectView.frame = tableView.bounds;
                        tableView.backgroundView = _leftEffectView;
                        break;
                        
                    case PBRevealControllerOperationReplaceRightController:
                        _rightEffectView.frame = tableView.bounds;
                        tableView.backgroundView = _rightEffectView;
                        break;
                        
                    default:
                        break;
                }
                tableView.backgroundColor = [UIColor clearColor];
                tableView.separatorEffect = vibancyEffect;
            }
            else {
                UIView *sideView = sideViewController.view;
                if ([sideViewController isKindOfClass:[UINavigationController class]]) {
                    UINavigationController *nc = (UINavigationController *)sideViewController;
                    sideView = nc.topViewController.view;
                }
                sideView.backgroundColor = [UIColor clearColor];
                
                switch (operation) {
                    case PBRevealControllerOperationReplaceLeftController:
                        _leftEffectView.frame = sideView.bounds;
                        [sideView addSubview:_leftEffectView];
                        break;
                        
                    case PBRevealControllerOperationReplaceRightController:
                        _rightEffectView.frame = sideView.bounds;
                        [sideView addSubview:_rightEffectView];
                        break;
                        
                    default:
                        break;
                }
            }
        }
        else {
            if (tableView) {
                tableView.backgroundView = nil;
                tableView.separatorEffect = nil;
            }
            else {
                switch (operation) {
                    case PBRevealControllerOperationReplaceLeftController:
                        [_leftEffectView removeFromSuperview];
                        break;
                        
                    case PBRevealControllerOperationReplaceRightController:
                        [_rightEffectView removeFromSuperview];
                        break;
                        
                    default:
                        break;
                }
            }
            switch (operation) {
                case PBRevealControllerOperationReplaceLeftController:
                    self.leftEffectView = nil;
                    break;
                    
                case PBRevealControllerOperationReplaceRightController:
                    self.rightEffectView = nil;
                    break;
                    
                default:
                    break;
            }
        }
    }
}

- (void)setLeftViewController:(UIViewController *)leftViewController
{
    [self setLeftViewController:leftViewController animated:NO];
}

- (void)setLeftViewController:(UIViewController *)leftViewController animated:(BOOL)animated
{
    if (_rightPresentViewHierarchically) {
        CGRect frame = [self adjustsFrameForController:leftViewController];
        leftViewController.view.frame = frame;
    }
    [self reloadSideBlurEffectStyle:_leftViewBlurEffectStyle forController:leftViewController forOperation:PBRevealControllerOperationReplaceLeftController];

    if (_isLeftViewOpen) {
        [self _swapFromViewController:_leftViewController toViewController:leftViewController operation:PBRevealControllerOperationReplaceLeftController animated:animated];
    }
    _leftViewController = leftViewController;
    [self reloadLeftShadow];
}

- (void)setMainViewController:(UIViewController *)mainViewController
{
    [self setMainViewController:mainViewController animated:NO];
}

- (void)setMainViewController:(UIViewController *)mainViewController animated:(BOOL)animated
{
    if (_mainViewController && animated) {
        [self _swapFromViewController:_mainViewController toViewController:mainViewController operation:PBRevealControllerOperationReplaceMainController animated:animated];
    }
    _mainViewController = mainViewController;
    [self reloadMainShadow];
}

- (void)setRightViewController:(UIViewController *)rightViewController
{
    [self setRightViewController:rightViewController animated:NO];
}

- (void)setRightViewController:(UIViewController *)rightViewController animated:(BOOL)animated
{
    if (_rightPresentViewHierarchically) {
        CGRect frame = [self adjustsFrameForController:rightViewController];
        rightViewController.view.frame = frame;
    }
    [self reloadSideBlurEffectStyle:_rightViewBlurEffectStyle forController:rightViewController forOperation:PBRevealControllerOperationReplaceRightController];

    if (_isRightViewOpen) {
        [self _swapFromViewController:_rightViewController toViewController:rightViewController operation:PBRevealControllerOperationReplaceRightController animated:animated];
    }
    _rightViewController = rightViewController;
    [self reloadRightShadow];
}

- (void)pushMainViewController:(UIViewController *)mainViewController animated:(BOOL)animated {
    PBRevealControllerOperation operation;
    if (_isLeftViewOpen) {
        operation = PBRevealControllerOperationPushMainControllerFromLeft;
    }
    else if (_isRightViewOpen) {
        operation = PBRevealControllerOperationPushMainControllerFromRight;
    }
    else {
        return;
    }
    UIViewController *fromViewController = _mainViewController;
    [self setMainViewController:mainViewController];
    [self _pushFromViewController:fromViewController toViewController:mainViewController operation:operation animated:animated];
}

- (void)_swapFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController operation:(PBRevealControllerOperation)operation animated:(BOOL)animated
{
    NSTimeInterval duration = animated ? _replaceViewAnimationDuration : 0.0;
    CGFloat fromAlpha = fromViewController.view.alpha;
    CGFloat toAlpha = toViewController.view.alpha;
    
    if (fromViewController != toViewController) {
        
        toViewController.view.frame = fromViewController.view.frame;
        
        if ([_delegate respondsToSelector:@selector(revealController:willAddViewController:forOperation:animated:)]) {
            [_delegate revealController:self willAddViewController:toViewController forOperation:operation animated:animated];
        }
        
        switch (operation) {
            case PBRevealControllerOperationReplaceLeftController:
            case PBRevealControllerOperationReplaceRightController:
                [_contentView insertSubview:toViewController.view belowSubview:fromViewController.view];
                break;
                
            case PBRevealControllerOperationReplaceMainController:
                [_contentView insertSubview:toViewController.view belowSubview:fromViewController.view];
                [_contentView addGestureRecognizer:_tapGestureRecognizer];
                [_contentView addGestureRecognizer:_panGestureRecognizer];
                break;
                
            default:
                break;
        }
        
        [self addChildViewController:toViewController];
        [fromViewController willMoveToParentViewController:nil];
        
        void (^completion)() = ^{
            [fromViewController.view removeFromSuperview];
            [fromViewController removeFromParentViewController];
            [toViewController didMoveToParentViewController:self];
            fromViewController.view.alpha = fromAlpha;
            if ([_delegate respondsToSelector:@selector(revealController:didAddViewController:forOperation:animated:)]) {
                [_delegate revealController:self didAddViewController:toViewController forOperation:operation animated:animated];
            }
        };
        
        void (^customBlock)();
        
        if ([_delegate respondsToSelector:@selector(revealController:blockForOperation:fromViewController:toViewController:finalBlock:)]) {
            customBlock = [_delegate revealController:self blockForOperation:operation fromViewController:fromViewController toViewController:toViewController finalBlock:completion];
        }
        
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 7.0) {
            id<UIViewControllerAnimatedTransitioning>animator = nil;
            if ([_delegate respondsToSelector:@selector(revealController:animationControllerForTransitionFromViewController:toViewController:forOperation:)]) {
                animator = [_delegate revealController:self animationControllerForTransitionFromViewController:fromViewController toViewController:toViewController forOperation:operation];
            }
            if (animator) {
                PBContextTransitionObject *transitioningObject = [[PBContextTransitionObject alloc]initWithRevealController:self containerView:_contentView fromViewController:fromViewController toViewController:toViewController completion:completion];
                [animator animateTransition:transitioningObject];
                return;
            }
        }
        if (customBlock) {
            customBlock();
        }
        else {
            toViewController.view.alpha = 0.8;
            [UIView animateWithDuration:duration delay:0. options:UIViewAnimationOptionTransitionNone animations:^{
                fromViewController.view.alpha = 0.;
                toViewController.view.alpha = toAlpha;
            } completion:^(BOOL finished) {
                completion();
            }];
        }
    }
}

- (void)_pushFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController operation:(PBRevealControllerOperation)operation animated:(BOOL)animated
{
    NSTimeInterval duration = animated ? (_isLeftViewOpen ? _leftToggleAnimationDuration : _rightToggleAnimationDuration) : 0.0;
    CGFloat fromAlpha = fromViewController.view.alpha;
    CGFloat toAlpha = toViewController.view.alpha;
    
    if (fromViewController == toViewController) {
        if (operation == PBRevealControllerOperationPushMainControllerFromLeft) {
            [self hideLeftViewAnimated:YES];
        }
        if (operation == PBRevealControllerOperationPushMainControllerFromRight) {
            [self hideRightViewAnimated:YES];
        }
        return;
    }
    
    toViewController.view.frame = fromViewController.view.frame;
    
    if ([_delegate respondsToSelector:@selector(revealController:willAddViewController:forOperation:animated:)]) {
        [_delegate revealController:self willAddViewController:toViewController forOperation:operation animated:animated];
    }
    
    void (^completion)() = ^{
        [fromViewController.view removeFromSuperview];
        [fromViewController removeFromParentViewController];
        [toViewController didMoveToParentViewController:self];
        
        if (operation == PBRevealControllerOperationPushMainControllerFromLeft) {
            [self hideLeftViewAnimated:YES];
        }
        if (operation == PBRevealControllerOperationPushMainControllerFromRight) {
            [self hideRightViewAnimated:YES];
        }
        [_contentView addGestureRecognizer:_tapGestureRecognizer];
        [_contentView addGestureRecognizer:_panGestureRecognizer];

        if ([_delegate respondsToSelector:@selector(revealController:didAddViewController:forOperation:animated:)]) {
            [_delegate revealController:self didAddViewController:toViewController forOperation:operation animated:animated];
        }
    };
    
    [_contentView insertSubview:toViewController.view belowSubview:fromViewController.view];
    
    [self addChildViewController:toViewController];
    [fromViewController willMoveToParentViewController:nil];
    
    if (_toggleAnimationType == PBRevealToggleAnimationTypeNone) {
        completion();
    }
    
    else if (_toggleAnimationType == PBRevealToggleAnimationTypeCrossDissolve) {
        toViewController.view.alpha = 0.8;
        [UIView animateWithDuration:duration delay:0. options:UIViewAnimationOptionTransitionNone animations:^{
            fromViewController.view.alpha = 0.;
            toViewController.view.alpha = toAlpha;
        } completion:^(BOOL finished) {
            completion();
            fromViewController.view.alpha = fromAlpha;
        }];
    }
    
    else if (_toggleAnimationType == PBRevealToggleAnimationTypePushSideView) {
        UIViewController *sideViewController;
        CGRect mainFrame, sideFrame;
        
        sideViewController = (_isLeftViewOpen ? _leftViewController : _rightViewController);

        [_contentView insertSubview:toViewController.view aboveSubview:fromViewController.view];
        
        mainFrame = toViewController.view.frame;
        mainFrame.origin.x = (_isLeftViewOpen ? _leftViewRevealWidth : -(_rightViewRevealWidth));
        toViewController.view.frame = mainFrame;
        
        mainFrame.origin.x = 0.;
        
        sideFrame = sideViewController.view.frame;
        sideFrame.origin.x = (_isLeftViewOpen ? -(_leftViewRevealWidth) : self.view.bounds.size.width);
        
        [UIView animateWithDuration:duration delay:0. options:UIViewAnimationOptionLayoutSubviews animations:^{
            toViewController.view.frame = mainFrame;
            sideViewController.view.frame = sideFrame;
        } completion:^(BOOL finished) {
            completion();
        }];
    }
    
    else if (_toggleAnimationType == PBRevealToggleAnimationTypeSpring) {
        UIViewController *sideViewController;
        BOOL sidePresentViewOnTop;
        __block CGRect mainFrame;
        __block CGRect sideFrame;
        

        sideViewController = (_isLeftViewOpen ? _leftViewController : _rightViewController);

        [_contentView insertSubview:toViewController.view aboveSubview:fromViewController.view];

        sidePresentViewOnTop = (_isLeftViewOpen ? _leftPresentViewOnTop : _rightPresentViewOnTop);
        
        sideFrame = sideViewController.view.frame;
        sideFrame.origin.x += (_isLeftViewOpen ? 0. : -(_rightViewRevealOverdraw));
        sideFrame.size.width += (_isLeftViewOpen ? _leftViewRevealOverdraw : _rightViewRevealOverdraw);
        
        mainFrame = toViewController.view.frame;
        mainFrame.origin.x = (_isLeftViewOpen ? _leftViewRevealWidth + _leftViewRevealOverdraw : - (_rightViewRevealWidth) - _rightViewRevealOverdraw);
        
        toViewController.view.hidden = YES;
    
        [UIView animateWithDuration:duration/2 delay:0. options:UIViewAnimationOptionLayoutSubviews animations:^{
            sideViewController.view.frame = sideFrame;
            if (!sidePresentViewOnTop) {
                fromViewController.view.frame = mainFrame;
                toViewController.view.frame = mainFrame;
            }
        } completion:^(BOOL finished) {
            toViewController.view.frame = mainFrame;
            mainFrame.origin.x = 0.;
            
            sideFrame.origin.x = (_isLeftViewOpen ? -(_leftViewRevealWidth) : self.view.bounds.size.width);
            sideFrame.size.width = (_isLeftViewOpen ? _leftViewRevealWidth : _rightViewRevealWidth);
            
            toViewController.view.hidden = NO;

            [UIView animateWithDuration:duration/2 delay:0. options:UIViewAnimationOptionLayoutSubviews animations:^{
                sideViewController.view.frame = sideFrame;
                toViewController.view.frame = mainFrame;
            } completion:^(BOOL finished) {
                completion();
            }];
        }];
    }
    
    else if (_toggleAnimationType == PBRevealToggleAnimationTypeCustom) {
        void (^customAnimation)();
        
        if ([_delegate respondsToSelector:@selector(revealController:animationBlockForOperation:fromViewController:toViewController:)]) {
            customAnimation = [_delegate revealController:self animationBlockForOperation:operation fromViewController:fromViewController toViewController:toViewController];
        }
        
        void (^customCompletion)();
        
        if ([_delegate respondsToSelector:@selector(revealController:completionBlockForOperation:fromViewController:toViewController:)]) {
            customCompletion = [_delegate revealController:self completionBlockForOperation:operation fromViewController:fromViewController toViewController:toViewController];
        }
        
        void (^customBlock)();
        
        if ([_delegate respondsToSelector:@selector(revealController:blockForOperation:fromViewController:toViewController:finalBlock:)]) {
            customBlock = [_delegate revealController:self blockForOperation:operation fromViewController:fromViewController toViewController:toViewController finalBlock:completion];
        }
        
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 7.0) {
            id<UIViewControllerAnimatedTransitioning>animator = nil;
            if ([_delegate respondsToSelector:@selector(revealController:animationControllerForTransitionFromViewController:toViewController:forOperation:)]) {
                animator = [_delegate revealController:self animationControllerForTransitionFromViewController:fromViewController toViewController:toViewController forOperation:operation];
            }
            if (animator) {
                PBContextTransitionObject *transitioningObject = [[PBContextTransitionObject alloc]initWithRevealController:self containerView:_contentView fromViewController:fromViewController toViewController:toViewController completion:completion];
                [animator animateTransition:transitioningObject];
                return;
            }
        }
        
        if (customBlock) {
            customBlock();
        }
        else if (customAnimation) {
            [UIView animateWithDuration:duration delay:0. options:UIViewAnimationOptionLayoutSubviews animations:^{
                customAnimation();
            } completion:^(BOOL finished) {
                completion();
                if (customCompletion) customCompletion();
            }];
        }
    }
}

#pragma mark - Reveal and hide actions

- (IBAction)revealLeftView
{
    if (_leftViewController) {
        if (_isLeftViewOpen) {
            [self hideLeftViewAnimated:YES];
            return;
        }
        if (_isRightViewOpen) {
            [self hideRightViewAnimated:YES];
        }
        if ([_delegate respondsToSelector:@selector(revealController:shouldShowLeftViewController:)]) {
            if ([_delegate revealController:self shouldShowLeftViewController:_leftViewController] == NO)
                return;
        }
        if ([_delegate respondsToSelector:@selector(revealController:willShowLeftViewController:)]) {
            [_delegate revealController:self willShowLeftViewController:_leftViewController];
        }
        
        CGRect leftFrame = _leftViewController.view.frame;
        
        if (_leftPresentViewOnTop) {
            leftFrame.origin.x = -(_leftViewRevealWidth);
        }
        else {
            leftFrame.origin.x = -(_leftViewRevealDisplacement);
        }
        leftFrame.size.width = _leftViewRevealWidth;
        _leftViewController.view.frame = leftFrame;

        if (_leftPresentViewOnTop) {
            [_contentView addSubview:_leftViewController.view];
        }
        else {
            [_contentView insertSubview:_leftViewController.view belowSubview:_mainViewController.view];
        }
        [self addChildViewController:_leftViewController];
        [_leftViewController didMoveToParentViewController:self];
        
        void (^completion)() = ^{
            _isLeftViewOpen = YES;
            self.tapGestureRecognizer.cancelsTouchesInView = YES;
            if ([_delegate respondsToSelector:@selector(revealController:didShowLeftViewController:)]) {
                [_delegate revealController:self didShowLeftViewController:_leftViewController];
            }
        };
        
        leftFrame.origin.x = 0;
        leftFrame.size.width = _leftViewRevealWidth;

        CGRect mainFrame = _mainViewController.view.frame;
        if (!_leftPresentViewOnTop) {
            mainFrame.origin.x = _leftViewRevealWidth;
        }

        if ([[UIDevice currentDevice] systemVersion].floatValue >= 7.0) {
            [UIView animateWithDuration:_leftToggleAnimationDuration delay:0.0 usingSpringWithDamping:_leftToggleSpringDampingRatio initialSpringVelocity:_leftToggleSpringVelocity options:UIViewAnimationOptionLayoutSubviews animations:^{
                _leftViewController.view.frame = leftFrame;
                _mainViewController.view.frame = mainFrame;
            } completion:^(BOOL finished) {
                completion();
            }];
        }
        else {
            [UIView animateWithDuration:_leftToggleAnimationDuration delay:0.0 options:UIViewAnimationOptionLayoutSubviews animations:^{
                _leftViewController.view.frame = leftFrame;
                _mainViewController.view.frame = mainFrame;
            } completion:^(BOOL finished) {
                completion();
            }];
        }
    }
}

- (IBAction)revealRightView
{
    if (_rightViewController) {
        if (_isRightViewOpen) {
            [self hideRightViewAnimated:YES];
            return;
        }
        if (_isLeftViewOpen) {
            [self hideLeftViewAnimated:YES];
        }
        if ([_delegate respondsToSelector:@selector(revealController:shouldShowRightViewController:)]) {
            if ([_delegate revealController:self shouldShowRightViewController:_rightViewController] == NO)
                return;
        }
        if ([_delegate respondsToSelector:@selector(revealController:willShowRightViewController:)]) {
            [_delegate revealController:self willShowRightViewController:_rightViewController];
        }
        
        CGRect rightFrame = _rightViewController.view.frame;
        if (_rightPresentViewOnTop) {
            rightFrame.origin.x = self.view.bounds.size.width;
        }
        else {
            rightFrame.origin.x = self.view.bounds.size.width -(_rightViewRevealWidth) + _rightViewRevealDisplacement;
        }
        rightFrame.size.width = _rightViewRevealWidth;
        _rightViewController.view.frame = rightFrame;
        
        if (_rightPresentViewOnTop) {
            [_contentView addSubview:_rightViewController.view];
        }
        else {
            [_contentView insertSubview:_rightViewController.view belowSubview:_mainViewController.view];
        }
        [self addChildViewController:_rightViewController];
        [_rightViewController didMoveToParentViewController:self];
        
        void (^completion)() = ^{
            _isRightViewOpen = YES;
            self.tapGestureRecognizer.cancelsTouchesInView = YES;
            if ([_delegate respondsToSelector:@selector(revealController:didShowRightViewController:)]) {
                [_delegate revealController:self didShowRightViewController:_rightViewController];
            }
        };
        
        rightFrame.origin.x = self.view.bounds.size.width - _rightViewRevealWidth;
        rightFrame.size.width = _rightViewRevealWidth;
        
        CGRect mainFrame = _mainViewController.view.frame;
        if (!_rightPresentViewOnTop) {
            mainFrame.origin.x = -(_rightViewRevealWidth);
        }
        
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 7.0) {
            [UIView animateWithDuration:_rightToggleAnimationDuration delay:0.0 usingSpringWithDamping:_rightToggleSpringDampingRatio initialSpringVelocity:_rightToggleSpringVelocity options: UIViewAnimationOptionLayoutSubviews animations:^{
                _rightViewController.view.frame = rightFrame;
                _mainViewController.view.frame = mainFrame;
            } completion:^(BOOL finished) {
                completion();
            }];
        }
        else {
            [UIView animateWithDuration:_rightToggleAnimationDuration delay:0.0 options:UIViewAnimationOptionLayoutSubviews animations:^{
                _rightViewController.view.frame = rightFrame;
                _mainViewController.view.frame = mainFrame;
            } completion:^(BOOL finished) {
                completion();
            }];
        }
    }
}

- (void)hideLeftViewAnimated:(BOOL)animated
{
    if (_leftViewController) {
        if ([_delegate respondsToSelector:@selector(revealController:willHideLeftViewController:)]) {
            [_delegate revealController:self willHideLeftViewController:_leftViewController];
        }
        NSTimeInterval duration = animated ? _leftToggleAnimationDuration : 0.;
        
        CGRect leftFrame = _leftViewController.view.frame;
        if (_leftPresentViewOnTop) {
            leftFrame.origin.x = -(_leftViewRevealWidth);
        }
        else {
            leftFrame.origin.x = -(_leftViewRevealDisplacement);
        }
        leftFrame.size.width = _leftViewRevealWidth;
        
        CGRect mainFrame = _mainViewController.view.frame;
        mainFrame.origin.x = 0;
        
        void (^completion)() = ^{
            _isLeftViewOpen = NO;
            self.tapGestureRecognizer.cancelsTouchesInView = NO;
            if (_isRightViewOpen) {
                self.tapGestureRecognizer.cancelsTouchesInView = YES;
            }
            [_leftViewController.view removeFromSuperview];
            [_leftViewController willMoveToParentViewController:nil];
            [_leftViewController removeFromParentViewController];
            if ([_delegate respondsToSelector:@selector(revealController:didHideLeftViewController:)]) {
                [_delegate revealController:self didHideLeftViewController:_leftViewController];
            }
        };

        if ([[UIDevice currentDevice] systemVersion].floatValue >= 7.0) {
            [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:_leftToggleSpringDampingRatio initialSpringVelocity:_leftToggleSpringVelocity options:UIViewAnimationOptionLayoutSubviews animations:^{
                _leftViewController.view.frame = leftFrame;
                _mainViewController.view.frame = mainFrame;
            } completion:^(BOOL finished) {
                completion();
            }];
        }
        else {
            [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionLayoutSubviews animations:^{
                _leftViewController.view.frame = leftFrame;
                _mainViewController.view.frame = mainFrame;
            } completion:^(BOOL finished) {
                completion();
            }];
        }
    }
}

- (void)hideRightViewAnimated:(BOOL)animated
{
    if (_rightViewController) {
        if ([_delegate respondsToSelector:@selector(revealController:willHideRightViewController:)]) {
            [_delegate revealController:self willHideRightViewController:_rightViewController];
        }
        NSTimeInterval duration = animated ? _rightToggleAnimationDuration : 0.;
        
        CGRect rightFrame = _rightViewController.view.frame;
        
        if (_rightPresentViewOnTop) {
            rightFrame.origin.x = self.view.bounds.size.width;
        }
        else {
            rightFrame.origin.x = self.view.bounds.size.width -(_rightViewRevealWidth) + _rightViewRevealDisplacement;
        }
        rightFrame.size.width = _rightViewRevealWidth;
        
        CGRect mainFrame = _mainViewController.view.frame;
        mainFrame.origin.x = 0;
        
        void (^completion)() = ^{
            _isRightViewOpen = NO;
            self.tapGestureRecognizer.cancelsTouchesInView = NO;
            if (_isLeftViewOpen) {
                self.tapGestureRecognizer.cancelsTouchesInView = YES;
            }
            [_rightViewController.view removeFromSuperview];
            [_rightViewController willMoveToParentViewController:nil];
            [_rightViewController removeFromParentViewController];
            if ([_delegate respondsToSelector:@selector(revealController:didHideRightViewController:)]) {
                [_delegate revealController:self didHideRightViewController:_rightViewController];
            }
        };

        if ([[UIDevice currentDevice] systemVersion].floatValue >= 7.0) {
            [UIView animateWithDuration:duration delay:0. usingSpringWithDamping:_rightToggleSpringDampingRatio initialSpringVelocity:_rightToggleSpringVelocity options:UIViewAnimationOptionLayoutSubviews animations:^{
                _rightViewController.view.frame = rightFrame;
                _mainViewController.view.frame = mainFrame;
            } completion:^(BOOL finished) {
                completion();
            }];
        }
        else {
            [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionLayoutSubviews animations:^{
                _rightViewController.view.frame = rightFrame;
                _mainViewController.view.frame = mainFrame;
            } completion:^(BOOL finished) {
                completion();
            }];
        }
    }
}

#pragma mark - Gesture Recognizer

- (UITapGestureRecognizer *)tapGestureRecognizer
{
    if (_tapGestureRecognizer == nil)
    {
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTapGesture:)];
        
        _tapGestureRecognizer.cancelsTouchesInView = NO;
        _tapGestureRecognizer.delegate = self;
        
        [_contentView addGestureRecognizer:_tapGestureRecognizer];
    }
    return _tapGestureRecognizer;
}

- (UIPanGestureRecognizer*)panGestureRecognizer
{
    if ( _panGestureRecognizer == nil )
    {
        self.panGestureRecognizer = [[PBRevealViewControllerPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePanGesture:)];
        _panGestureRecognizer.delegate = self;
        
        [_mainViewController.view addGestureRecognizer:_panGestureRecognizer];
    }
    return _panGestureRecognizer;
}

#pragma mark - Gesture Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)recognizer
{
    if (recognizer == _tapGestureRecognizer) {
        if ([_delegate respondsToSelector:@selector(revealControllerTapGestureShouldBegin:)]) {
            if ([_delegate revealControllerTapGestureShouldBegin:self] == NO) {
                return NO;
            }
        }
    }
    if (recognizer == _panGestureRecognizer) {
        CGFloat velocity = [_panGestureRecognizer velocityInView:_mainViewController.view].x;
        if ([_delegate respondsToSelector:@selector(revealControllerPanGestureShouldBegin:direction:)]) {
            if ([_delegate revealControllerPanGestureShouldBegin:self direction:velocity > 0 ? PBRevealControllerPanDirectionRight : PBRevealControllerPanDirectionLeft] == NO) {
                return NO;
            }
        }
        if (_isLeftViewOpen || _isRightViewOpen) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ( gestureRecognizer == _panGestureRecognizer )
    {
        if ( [_delegate respondsToSelector:@selector(revealController:panGestureRecognizerShouldRecognizeSimultaneouslyWithGestureRecognizer:)] )
            if ( [_delegate revealController:self panGestureRecognizerShouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer] != NO )
                return YES;
    }
    if ( gestureRecognizer == _tapGestureRecognizer )
    {
        if ( [_delegate respondsToSelector:@selector(revealController:tapGestureRecognizerShouldRecognizeSimultaneouslyWithGestureRecognizer:)] )
            if ( [_delegate revealController:self tapGestureRecognizerShouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer] != NO )
                return YES;
    }
    
    return NO;
}

- (void)_moveLeftViewToPosition:(CGFloat)position
{
    if (_leftViewController) {
        if (![self.childViewControllers containsObject:_leftViewController]) {
            CGRect frame = _leftViewController.view.frame;
            if (_leftPresentViewOnTop) {
                frame.origin.x = -(_leftViewRevealWidth);
                frame.size.width = 0;
            }
            else {
                frame.origin.x = -(_leftViewRevealDisplacement);
                frame.size.width = _leftViewRevealWidth;
            }
            _leftViewController.view.frame = frame;
            if (_leftPresentViewOnTop) {
                [_contentView addSubview:_leftViewController.view];
            }
            else {
                [_contentView insertSubview:_leftViewController.view belowSubview:_mainViewController.view];
            }
            [self addChildViewController:_leftViewController];
            [_leftViewController didMoveToParentViewController:self];
        }
        
        CGRect leftFrame = _leftViewController.view.frame;
        if (_leftPresentViewOnTop) {
            leftFrame.origin.x = 0;
        }
        
        CGRect mainFrame = _mainViewController.view.frame;
        
        if (position <= 0) {
            [self hideLeftViewAnimated:YES];
            self.panGestureRecognizer.state = UIGestureRecognizerStateCancelled;
        }
        else if (position < _leftViewRevealWidth) {
            if (_leftPresentViewOnTop) {
                leftFrame.size.width = position;
            }
            else {
                leftFrame.origin.x = -(_leftViewRevealDisplacement - (position * _leftViewRevealDisplacement / _leftViewRevealWidth));
                mainFrame.origin.x = position;
                _mainViewController.view.frame = mainFrame;
            }
            _leftViewController.view.frame = leftFrame;
        }
        else {
            if ([_delegate respondsToSelector:@selector(revealController:willShowLeftViewController:)]) {
                [_delegate revealController:self willShowLeftViewController:_leftViewController];
            }
            _isLeftViewOpen = YES;
            self.tapGestureRecognizer.cancelsTouchesInView = YES;
            
            leftFrame.origin.x = 0.;
            leftFrame.size.width = _leftViewRevealWidth;
            
            if (!_leftPresentViewOnTop) {
                mainFrame.origin.x = _leftViewRevealWidth;
            }
            
            void (^completion)() = ^{
                if ([_delegate respondsToSelector:@selector(revealController:didShowLeftViewController:)]) {
                    [_delegate revealController:self didShowLeftViewController:_leftViewController];
                }
            };

            if ([[UIDevice currentDevice] systemVersion].floatValue >= 7.0) {
                [UIView animateWithDuration:_leftToggleAnimationDuration delay:0.0 usingSpringWithDamping:_leftToggleSpringDampingRatio initialSpringVelocity:_leftToggleSpringVelocity options:UIViewAnimationOptionTransitionNone animations:^{
                    _leftViewController.view.frame = leftFrame;
                    _mainViewController.view.frame = mainFrame;
                } completion:^(BOOL finished) {
                    completion();
                }];
            }
            else {
                [UIView animateWithDuration:_leftToggleAnimationDuration delay:0.0 options:UIViewAnimationOptionTransitionNone animations:^{
                    _leftViewController.view.frame = leftFrame;
                    _mainViewController.view.frame = mainFrame;
                } completion:^(BOOL finished) {
                    completion();
                }];
            }
        }
    }
}

- (void)_moveRightViewToPosition:(CGFloat)position
{
    if (_rightViewController) {
        if (![self.childViewControllers containsObject:_rightViewController]) {
            CGRect frame = _rightViewController.view.frame;
            if (_rightPresentViewOnTop) {
                frame.origin.x = self.view.bounds.size.width;
                frame.size.width = _rightViewRevealWidth;
            }
            else {
                frame.origin.x = self.view.bounds.size.width - _rightViewRevealWidth + _rightViewRevealDisplacement;
                frame.size.width = _rightViewRevealWidth;
            }
            _rightViewController.view.frame = frame;
            if (_rightPresentViewOnTop) {
                [_contentView addSubview:_rightViewController.view];
            }
            else {
                [_contentView insertSubview:_rightViewController.view belowSubview:_mainViewController.view];
            }
            [self addChildViewController:_rightViewController];
            [_rightViewController didMoveToParentViewController:self];
        }

        CGRect rightFrame = _rightViewController.view.frame;
        
        CGRect mainFrame = _mainViewController.view.frame;
        
        if (position >= 0) {
            [self hideRightViewAnimated:YES];
            self.panGestureRecognizer.state = UIGestureRecognizerStateCancelled;
        }
        else if (ABS(position) < _rightViewRevealWidth) {
            if (_rightPresentViewOnTop) {
                rightFrame.origin.x = self.view.bounds.size.width - ABS(position);
            }
            else {
                CGFloat displacement = _rightViewRevealDisplacement - (ABS(position) * _rightViewRevealDisplacement / _rightViewRevealWidth);
                rightFrame.origin.x = self.view.bounds.size.width - _rightViewRevealWidth + displacement;
                mainFrame.origin.x = position;
                _mainViewController.view.frame = mainFrame;
            }
            _rightViewController.view.frame = rightFrame;
        }
        else {
            if ([_delegate respondsToSelector:@selector(revealController:willShowRightViewController:)]) {
                [_delegate revealController:self willShowRightViewController:_rightViewController];
            }
            _isRightViewOpen = YES;
            self.tapGestureRecognizer.cancelsTouchesInView = YES;
            
//            rightFrame.origin.x = [UIScreen mainScreen].bounds.size.width - _rightViewRevealWidth;
            rightFrame.origin.x = self.view.bounds.size.width - _rightViewRevealWidth;
            rightFrame.size.width = _rightViewRevealWidth;
            if (!_rightPresentViewOnTop) {
                mainFrame.origin.x = - (_rightViewRevealWidth);
            }
            
            void (^completion)() = ^{
                if ([_delegate respondsToSelector:@selector(revealController:didShowRightViewController:)]) {
                    [_delegate revealController:self didShowRightViewController:_rightViewController];
                }
            };
            
            if ([[UIDevice currentDevice] systemVersion].floatValue >= 7.0) {
                [UIView animateWithDuration:_rightToggleAnimationDuration delay:0.0 usingSpringWithDamping:_rightToggleSpringDampingRatio initialSpringVelocity:_rightToggleSpringVelocity options:UIViewAnimationOptionTransitionNone animations:^{
                    _rightViewController.view.frame = rightFrame;
                    _mainViewController.view.frame = mainFrame;
                } completion:^(BOOL finished) {
                    completion();
                }];
            }
            else {
                [UIView animateWithDuration:_rightToggleAnimationDuration delay:0.0 options:UIViewAnimationOptionTransitionNone animations:^{
                    _rightViewController.view.frame = rightFrame;
                    _mainViewController.view.frame = mainFrame;
                } completion:^(BOOL finished) {
                    completion();
                }];
            }
        }
    }
}

#pragma mark - UserInteractionEnabling

- (void)disableUserInteraction
{
    [_contentView setUserInteractionEnabled:NO];
}

- (void)restoreUserInteraction
{
    // we use the stored userInteraction state just in case a developer decided to have our view interaction disabled before handle
    [_contentView setUserInteractionEnabled:_userInteractionStore];
}


#pragma mark - Gesture Handle

- (void)_handleTapGesture:(UITapGestureRecognizer *)recognizer
{
    if (_isLeftViewOpen) {
        [self hideLeftViewAnimated:YES];
    }
    if (_isRightViewOpen) {
        [self hideRightViewAnimated:YES];
    }
}

- (void)_handlePanGesture:(UIPanGestureRecognizer *)recognizer
{
    CGFloat position = [recognizer translationInView:_mainViewController.view].x;
    CGFloat velocity = [recognizer velocityInView:_mainViewController.view].x;
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self notifyPanGestureBegan:position];
            if (velocity > 0 && _leftViewController && !_isRightViewDragging) {
                _isLeftViewDragging = YES;
            }
            else if (_rightViewController) {
                _isRightViewDragging = YES;
            }
            [self disableUserInteraction];
            if (ABS(velocity) > _swipeVelocity) {
                if (_isLeftViewDragging) {
                    [self _moveLeftViewToPosition:_leftViewRevealWidth];
                }
                else {
                    if (velocity < 0) [self _moveRightViewToPosition:-(_rightViewRevealWidth)];
                }
            }
            break;
            
        case UIGestureRecognizerStateChanged:
            [self notifyPanGestureMoved:position];
            if (_isLeftViewOpen || _isRightViewOpen) {
                self.panGestureRecognizer.state = UIGestureRecognizerStateCancelled;
                break;
            }
            
            if (_isLeftViewDragging) {
                [self _moveLeftViewToPosition:position];
            }
            else {
                [self _moveRightViewToPosition:position];
            }
            break;
            
        case UIGestureRecognizerStateEnded:
            if (_isLeftViewOpen || _isRightViewOpen) {
                [self notifyPanGestureEnded:position];
                break;
            }
            
            if (_isLeftViewDragging) {
                if (position > _leftViewRevealWidth * 0.50) {
                    [self _moveLeftViewToPosition:_leftViewRevealWidth];
                }
                else {
                    [self hideLeftViewAnimated:YES];
                }
            }
            else {
                if (ABS(position) > _rightViewRevealWidth * 0.50) {
                    [self _moveRightViewToPosition:-(_rightViewRevealWidth)];
                }
                else {
                    [self hideRightViewAnimated:YES];
                }
            }
            [self notifyPanGestureEnded:position];
            break;
            
        case UIGestureRecognizerStateCancelled:
            [self notifyPanGestureEnded:position];
            break;
            
        default:
            break;
    }
}

- (void)notifyPanGestureBegan:(CGFloat)position
{
    if ([_delegate respondsToSelector:@selector(revealControllerPanGestureBegan:direction:)]) {
        CGFloat velocity = [_panGestureRecognizer velocityInView:_mainViewController.view].x;
        [_delegate revealControllerPanGestureBegan:self direction:velocity > 0 ? PBRevealControllerPanDirectionRight : PBRevealControllerPanDirectionLeft];
    }
}

- (void)notifyPanGestureMoved:(CGFloat)position
{
    if ([_delegate respondsToSelector:@selector(revealControllerPanGestureMoved:direction:)]) {
        CGFloat velocity = [_panGestureRecognizer velocityInView:_mainViewController.view].x;
        [_delegate revealControllerPanGestureMoved:self direction:velocity > 0 ? PBRevealControllerPanDirectionRight : PBRevealControllerPanDirectionLeft];
    }
}

- (void)notifyPanGestureEnded:(CGFloat)position
{
    _isLeftViewDragging = NO;
    _isRightViewDragging = NO;
    [self restoreUserInteraction];
    if ([_delegate respondsToSelector:@selector(revealControllerPanGestureEnded:direction:)]) {
        CGFloat velocity = [_panGestureRecognizer velocityInView:_mainViewController.view].x;
        [_delegate revealControllerPanGestureEnded:self direction:velocity > 0 ? PBRevealControllerPanDirectionRight : PBRevealControllerPanDirectionLeft];
    }
}

# pragma mark - Adjusts frames

- (CGRect)adjustsFrameForController:(UIViewController *)sideViewController
{
    CGFloat barHeight = [_navigationBar sizeThatFits:CGSizeMake(100,100)].height;
    CGRect frame = sideViewController.view.frame;

    if ([[UIDevice currentDevice] systemVersion].floatValue < 7.0) {
        frame.origin.y = barHeight;
        frame.size.height = self.view.bounds.size.height - barHeight;
    }
    else {
        BOOL statusBarIsHidden = [UIApplication sharedApplication].statusBarFrame.size.height == 0.;
        frame.origin.y = barHeight + (statusBarIsHidden ? 0 : 20);
        frame.size.height = self.view.frame.size.height - barHeight - (statusBarIsHidden ? 0 : 20);
    }
    return frame;
}

# pragma mark - Override rotation

- (void)viewWillTransitionToSize:(CGSize)size
{
    CGRect frame;
    
    if (_leftPresentViewHierarchically) {
        frame = [self adjustsFrameForController:_leftViewController];
    }
    else {
        frame = _leftViewController.view.frame;
        frame.size.height = size.height;
    }
    
    frame.size.width = _leftViewRevealWidth;
    
    _leftViewController.view.frame = frame;
    
    if (_rightPresentViewHierarchically) {
        frame = [self adjustsFrameForController:_rightViewController];
    }
    else {
        frame = _rightViewController.view.frame;
        frame.size.height = size.height;
    }
    
    frame.origin.x = size.width;
    if (_isRightViewOpen) {
        frame.origin.x = size.width - _rightViewRevealWidth;
    }
    frame.size.width = _rightViewRevealWidth;
    
    _rightViewController.view.frame = frame;
}

# pragma mark - Override rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         [self viewWillTransitionToSize:size];
         
     } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         
     }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

// iOS < 8.0
- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self viewWillTransitionToSize:self.view.bounds.size];
}
//

# pragma mark - Helpers

- (UITableView *)tableViewInView:(UIView *)view
{
    if ([view isKindOfClass:[UITableView class]]) {
        return (UITableView *)view;
    }
    for (UIView *subview in view.subviews)
    {
        if ([subview isKindOfClass:[UITableView class]]) {
            return (UITableView *)subview;
        }
        
        if ([subview.subviews count] > 0)
        {
            [self tableViewInView:subview];
        }
    }
    return nil;
}

+ (UIImage *)screenShot
{
    // Create graphics context with screen size
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    UIGraphicsBeginImageContext(screenRect.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor blackColor] set];
    CGContextFillRect(ctx, screenRect);
    
    // Get reference to our window
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    
    // Transfer content into our context
    [window.layer renderInContext:ctx];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)cropedImage:(UIImage *)image toRect:(CGRect)rect
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    UIImage *newImage   = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return newImage;
}


@end
