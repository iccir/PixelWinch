//
//  calculate_grapple.cl
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-11.
//
//



inline float _rgb_to_xyz_n(float n)
{
    return (n > 0.04045f ? pow((n + 0.055f)/1.055f, 2.4f) : n/12.92f)*100.0f;
}


inline float _xyz_to_lab_n(float n)
{
    return n > 0.008856f ? pow(n, 1.0f/3.0f) : (903.3f * n + 16.0f) / 116.0f;
}


float4 rgb_to_xyz(float4 rgb)
{
    float r = _rgb_to_xyz_n(rgb.x);
    float g = _rgb_to_xyz_n(rgb.y);
    float b = _rgb_to_xyz_n(rgb.z);

    return (float4)(
        r*0.4124 + g*0.3576 + b*0.1805,
        r*0.2126 + g*0.7152 + b*0.0722,
        r*0.0193 + g*0.1192 + b*0.9505,
        0
    );
}


float4 xyz_to_lab(float4 xyz)
{
    float x = _xyz_to_lab_n(xyz.x / 95.047);
    float y = _xyz_to_lab_n(xyz.y / 100.000);
    float z = _xyz_to_lab_n(xyz.z / 108.883);

    return (float4)(
        max(0.f, (116.f * y) - 16.f),
        500.f * (x - y),
        200.f * (y - z),
        0
    );
}


kernel void convert_rgb_to_lab(global uchar *rgb8, global float4 *LAB)
{
    int i = get_global_id(0);
    int r = i * 3;

    float4 rgb = (float4)(
        (float)rgb8[r] / 255.0f,
        (float)rgb8[r+1] / 255.0f,
        (float)rgb8[r+2] / 255.0f,
        0
    );

    float4 xyz = rgb_to_xyz(rgb);
    LAB[i] = xyz_to_lab(xyz);
}


kernel void convert_rgba_to_lab(global uchar4 *rgb8, global float4 *LAB)
{
    int i = get_global_id(0);

    float4 rgb = (float4)(
        (float)rgb8[i].x / 255.0f,
        (float)rgb8[i].y / 255.0f,
        (float)rgb8[i].z / 255.0f,
        0
    );

    float4 xyz = rgb_to_xyz(rgb);
    LAB[i] = xyz_to_lab(xyz);
}


kernel void make_delta_map(global __read_only float4 *LAB, int offset, global uchar *map)
{
    int i = get_global_id(0);

    float4 p1 = LAB[i];
    float4 p2 = LAB[i + offset];
    
    float d = distance(p1, p2);
    
    float result_f = ceil((d / 258.693) * 254.0);
    uchar result_8 = (uchar)(result_f);
    map[i] = result_8;

}
