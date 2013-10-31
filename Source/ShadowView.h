//
//  ShadowView.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-10-29.
//
//

#import <Cocoa/Cocoa.h>

@interface ShadowView : XUIView

@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, strong) NSShadow *shadow;

@end
