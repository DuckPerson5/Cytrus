//
//  CytrusObjC.h
//  Cytrus
//
//  Created by Jarrod Norwell on 1/8/24.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/CAMetalLayer.h>
#import <UIKit/UIKit.h>

#import "GameInformation/GameInformation.h"


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, VirtualControllerButtonType) {
    // 3DS Controls
    VirtualControllerButtonTypeA = 700,
    VirtualControllerButtonTypeB = 701,
    VirtualControllerButtonTypeX = 702,
    VirtualControllerButtonTypeY = 703,
    VirtualControllerButtonTypeStart = 704,
    VirtualControllerButtonTypeSelect = 705,
    VirtualControllerButtonTypeHome = 706,
    VirtualControllerButtonTypeTriggerZL = 707,
    VirtualControllerButtonTypeTriggerZR = 708,
    VirtualControllerButtonTypeDirectionalPadUp = 709,
    VirtualControllerButtonTypeDirectionalPadDown = 710,
    VirtualControllerButtonTypeDirectionalPadLeft = 711,
    VirtualControllerButtonTypeDirectionalPadRight = 712,
    VirtualControllerButtonTypeCirclePad = 713,
    VirtualControllerButtonTypeCirclePadUp = 714,
    VirtualControllerButtonTypeCirclePadDown = 715,
    VirtualControllerButtonTypeCirclePadLeft = 716,
    VirtualControllerButtonTypeCirclePadRight = 717,
    VirtualControllerButtonTypeCStick = 718,
    VirtualControllerButtonTypeCStickUp = 719,
    VirtualControllerButtonTypeCStickDown = 720,
    VirtualControllerButtonTypeCStickLeft = 771,
    VirtualControllerButtonTypeCStickRight = 772,
    VirtualControllerButtonTypeTriggerL = 773,
    VirtualControllerButtonTypeTriggerR = 774,
    VirtualControllerButtonTypeDebug = 781,
    VirtualControllerButtonTypeGPIO14 = 782
};

//

@interface KeyboardConfig : NSObject
@property (nonatomic, strong) NSString *hintText;

-(KeyboardConfig *) initWithHintText:(NSString *)hintText;
@end

//


@interface CytrusObjC : NSObject {
    CGSize size;
}

@property (nonatomic, strong) GameInformation *gameInformation;

+(CytrusObjC *) sharedInstance NS_SWIFT_NAME(shared());
-(void) configureLayer:(CAMetalLayer *)layer NS_SWIFT_NAME(configure(layer:));
-(void) insertGame:(NSURL *)url NS_SWIFT_NAME(insert(game:));
-(void) step;

-(void) orientationChanged:(UIInterfaceOrientation)orientation;

-(void) touchBeganAtPoint:(CGPoint)point;
-(void) touchEnded;
-(void) touchMovedAtPoint:(CGPoint)point;

-(void) virtualControllerButtonDown:(VirtualControllerButtonType)button;
-(void) virtualControllerButtonUp:(VirtualControllerButtonType)button;
@end

NS_ASSUME_NONNULL_END
