//
//  MapFunctions.c
//  Pixel Winch
//
//  Created by Ricci Adams on 2014-06-07.
//
//

#include "WinchFastMath.h"
#include <stdio.h>
#include <cpuid.h>
#include <smmintrin.h>

#include <Accelerate/Accelerate.h>


static __inline__ __m128 sLoadFloats(const float *value) {
    __m128 xy = _mm_loadl_pi(_mm_setzero_ps(), (const __m64*)value);
    __m128 z = _mm_load_ss(&value[2]);
    return _mm_movelh_ps(xy, z);
}


extern void CalculateImageDistanceMap(float *inLAB, UInt8 *outHorizontalMap, UInt8 *outVerticalMap, const size_t width, const size_t height)
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    size_t width_height = width * height;

    float *hDistance = malloc(sizeof(float) * width_height);
    float *vDistance = malloc(sizeof(float) * width_height);
    float *maxArray  = malloc(sizeof(float) * height);

    dispatch_apply(height, queue, ^(size_t y) {
        size_t y_width = y * width;

        float max = 0;

        float *here  = &inLAB[(y_width * 4)];
        float *right = &inLAB[((y_width) + 1)     * 4];
        float *down  = &inLAB[((y_width) + width) * 4];

        for (size_t x = 0; x < width; x++) {
            __m128 here128  = sLoadFloats(here);
            __m128 right128 = sLoadFloats(right);
            __m128 down128  = sLoadFloats(down);

            __m128 hDelta   = _mm_sub_ps(here128, right128);
            __m128 vDelta   = _mm_sub_ps(here128, down128);

            hDelta = _mm_sqrt_ss(_mm_dp_ps(hDelta, hDelta, 0x71));
            vDelta = _mm_sqrt_ss(_mm_dp_ps(vDelta, vDelta, 0x71));

            float hD = _mm_cvtss_f32(hDelta);
            float vD = _mm_cvtss_f32(vDelta);
            
            hDistance[y_width + x] = hD;
            vDistance[y_width + x] = vD;

            if (hD > max) max = hD;
            if (vD > max) max = vD;

            here  += 4;
            right += 4;
            down  += 4;
        }
        
        maxArray[y] = max;
    });
    
    float actualMax;
    vDSP_maxv(maxArray, 1, &actualMax, height);

    dispatch_apply(height, queue, ^(size_t y) {
        const size_t y_width = y * width;
        const float f254 = 254.0f;

        float *hDistance_row = &hDistance[y_width];
        float *vDistance_row = &vDistance[y_width];

        vDSP_vsdiv(hDistance_row, 1, &actualMax, hDistance_row, 1, width);
        vDSP_vsmul(hDistance_row, 1, &f254,      hDistance_row, 1, width);

        vDSP_vsdiv(vDistance_row, 1, &actualMax, vDistance_row, 1, width);
        vDSP_vsmul(vDistance_row, 1, &f254,      vDistance_row, 1, width);

        for (size_t x = 0; x < width; x++) {
            size_t index = (y * width) + x;

            outHorizontalMap[index] = (UInt8)ceil(hDistance[index]);
            outVerticalMap[  index] = (UInt8)ceil(vDistance[index]);
        }
    });
    
    free(hDistance);
    free(vDistance);
    free(maxArray);
}
