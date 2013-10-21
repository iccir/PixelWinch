//
//  Compatibility.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-20.
//
//

#import "Compatibility.h"

#import <objc/runtime.h>


@implementation NSObject (MountainLionCompatibility)

- (void) compatibility_NSImage_drawInRect:(NSRect)rect
{
    [(NSImage *)self drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:nil];
}


+ (NSColor *) compatibility_NSColor_colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha
{
    return [NSColor colorWithGenericGamma22White:white alpha:alpha];
}


+ (NSColor *) compatibility_NSColor_colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
    return [NSColor colorWithSRGBRed:red green:green blue:blue alpha:alpha];
}


+ (NSColor *) compatibility_NSColor_colorWithHue: (CGFloat) hue
                                      saturation: (CGFloat) saturation
                                      brightness: (CGFloat) brightness
                                           alpha: (CGFloat) alpha
{
    float r = 0.0;
    float g = 0.0;
    float b = 0.0;

    if (saturation == 0.0) {
        r = g = b = brightness;

    } else {
        if (hue >= 1.0) hue -= 1.0;

        float sectorAsFloat = hue * 6;
        int   sectorAsInt   = (int)(sectorAsFloat);

        float f = sectorAsFloat - sectorAsInt;			// factorial part of h
        float p = brightness * ( 1 - saturation );
        float q = brightness * ( 1 - saturation * f );
        float t = brightness * ( 1 - saturation * ( 1 - f ) );
        float v = brightness;

        switch (sectorAsInt) {
        case 0:  r = v; g = t; b = p;  break;
        case 1:  r = q; g = v; b = p;  break;
        case 2:  r = p; g = v; b = t;  break;
        case 3:  r = p; g = q; b = v;  break;
        case 4:  r = t; g = p; b = v;  break;
        case 5:  r = v; g = p; b = q;  break;
        }
    }

    return [NSColor colorWithSRGBRed:r green:g blue:b alpha:alpha];
}


@end


static void AliasMethod(Class cls, char plusOrMinus, SEL originalSel, SEL aliasSel)
{
    if (plusOrMinus == '+') {
        const char *clsName = class_getName(cls);
        cls = objc_getMetaClass(clsName);
    }

    Method method = class_getInstanceMethod(cls, originalSel);

    if (method) {
        IMP         imp    = method_getImplementation(method);
        const char *types  = method_getTypeEncoding(method);

        class_addMethod(cls, aliasSel, imp, types);
    }
}


void InstallCompatibilityIfNeeded(void)
{
    Class NSColorClass = [NSColor class];
    Class NSImageClass = [NSImage class];

    if (![NSImage instancesRespondToSelector:@selector(drawInRect:)]) {
        AliasMethod(NSImageClass, '-', @selector(compatibility_NSImage_drawInRect:), @selector(drawInRect:));
    }

    if (![[NSColor class] respondsToSelector:@selector(colorWithWhite:alpha:)]) {
        AliasMethod(NSColorClass, '+', @selector(compatibility_NSColor_colorWithWhite:alpha:), @selector(colorWithWhite:alpha:));
    }

    if (![[NSColor class] respondsToSelector:@selector(colorWithRed:green:blue:alpha:)]) {
        AliasMethod(NSColorClass, '+', @selector(compatibility_NSColor_colorWithRed:green:blue:alpha:), @selector(colorWithRed:green:blue:alpha:));
    }
    
    if (![[NSColor class] respondsToSelector:@selector(colorWithHue:saturation:brightness:alpha:)]) {
        AliasMethod(NSColorClass, '+', @selector(compatibility_NSColor_colorWithHue:saturation:brightness:alpha:), @selector(colorWithHue:saturation:brightness:alpha:));
    }
}

