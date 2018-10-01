//
//  MapFunctions.c
//  Pixel Winch
//
//  Created by Ricci Adams on 2014-06-07.
//
//

#include <stdio.h>
#include <CoreFoundation/CoreFoundation.h>

#ifndef WINCH_FAST_MATH_H
#define WINCH_FAST_MATH_H

extern void CalculateImageDistanceMap(float *inLAB, UInt8 *outHorizontalMap, UInt8 *outVerticalMap, const size_t width, const size_t height);

#endif

