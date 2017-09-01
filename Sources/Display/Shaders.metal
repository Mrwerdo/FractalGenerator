#include <metal_stdlib>
using namespace metal;

#define M_PI 3.141592653589793238462643383

/// Basic implementation of complex numbers, with * + - operators, and a function to return the squared magnitude.
template<typename T>
struct complex
{
    T _x, _y;

    complex(T x, T y) : _x(x), _y(y) { }
    
    T sqmag() const {
        return _x*_x + _y*_y;
    }
    
    complex<T> operator*(const thread complex<T>& other) const {
        return complex(_x*other._x - _y*other._y,
                       _x*other._y + _y*other._x);
    }
    
    complex<T> operator+(const thread complex<T>& other) const {
        return complex(_x + other._x, _y + other._y);
    }
    
    complex<T> operator-(const thread complex<T>& other) const {
        return complex(_x - other._x, _y - other._y);
    }
    
    complex<T> operator*(const thread T& c) const {
        return complex(_x * c, _y * c);
    }
};


#define complexExtentX 3.5
#define complexExtentY 3
#define mandelbrotShiftX 0.2

/// Convert a point on the screen to a point in the complex plane.
template<typename T>
complex<T> screenToComplex(T x, T y, T width, T height)
{
    const T scale = max(complexExtentX/width, complexExtentY/height);
    
    return complex<T>((x-width/2)*scale, (y-height/2)*scale);
}


/// Both Mandelbrot and Julia sets use the same iterative algorithm to determine whether
/// a given point is in the set. Each point is colored based on how quickly it escape to infinity.
template<typename T>
float4 colorForIteration(complex<T> z, complex<T> c, int maxiters, float escape)
{
    for (int i = 0; i < maxiters; i++) {
        z = z*z + c;
        if (z.sqmag() > escape) {
            // Smoothing coloring, adapted from:
            // <https://en.wikipedia.org/wiki/Mandelbrot_set#Continuous_.28smooth.29_coloring>
            float hue = (i+1-log2(log10(z.sqmag())/2))/maxiters*4 * M_PI + 3;
            
            // Convert to RGB
            return float4((cos(hue)+1)/2,
                          (-cos(hue+M_PI/3)+1)/2,
                          (-cos(hue-M_PI/3)+1)/2,
                          1);
        }
    }
    
    return float4(0, 0, 0, 1);
}


/// Render a visualization of the Mandelbrot set into the `output` texture.
kernel void mandelbrotShader(texture2d<float, access::write> output [[texture(0)]],
                             uint2 upos [[thread_position_in_grid]])
{
    uint width = output.get_width();
    uint height = output.get_height();
    if (upos.x > width || upos.y > height) return;
    
    complex<float> z(0, 0);
    
    complex<float> c = screenToComplex<float>(upos.x - mandelbrotShiftX*width,
                                              upos.y,
                                              width, height);
    
    output.write(float4(colorForIteration(z, c, 100, 100)), upos);
}


/// Render a visualization of the Julia set for the point `screenPoint` into the `output` texture.
kernel void juliaShader(texture2d<float, access::write> output [[texture(0)]],
                        uint2 upos [[thread_position_in_grid]],
                        const device float2& screenPoint [[buffer(0)]])
{
    uint width = output.get_width();
    uint height = output.get_height();
    if (upos.x > width || upos.y > height) return;
    
    complex<float> z = screenToComplex<float>(upos.x, upos.y, width, height);
    
    complex<float> c = screenToComplex<float>(screenPoint.x - mandelbrotShiftX*width,
                                              screenPoint.y,
                                              width,
                                              height);
    
    output.write(float4(colorForIteration(z, c, 100, 50)), upos);
}

// ------------------------------------------------------------------------------
// Overtime Rendering
// ------------------------------------------------------------------------------

/// Both Mandelbrot and Julia sets use the same iterative algorithm to determine whether
/// a given point is in the set. Each point is colored based on how quickly it escape to infinity.
//template<typename T>
//float4 colorForIteration(complex<T> z, complex<T> c, int maxiters, float escape)
//{
//    for (int i = 0; i < maxiters; i++) {
//        z = z*z + c;
//        if (z.sqmag() > escape) {
//            // Smoothing coloring, adapted from:
//            // <https://en.wikipedia.org/wiki/Mandelbrot_set#Continuous_.28smooth.29_coloring>
//            float hue = (i+1-log2(log10(z.sqmag())/2))/maxiters*4 * M_PI + 3;
//
//            // Convert to RGB
//            return float4((cos(hue)+1)/2,
//                          (-cos(hue+M_PI/3)+1)/2,
//                          (-cos(hue-M_PI/3)+1)/2,
//                          1);
//        }
//    }
//
//    return float4(0, 0, 0, 1);
//}

template<typename T>
float4 colorPoint(complex<T> z, uint a, uint isComplete, uint maxAlpha)
{
    if (isComplete == 1) {
        int i = (int)a;
        float hue = (i+1-log2(log10(z.sqmag())/2))/maxAlpha*4 * M_PI + 3;
        
        // Convert to RGB
        return float4((cos(hue)+1)/2,
                      (-cos(hue+M_PI/3)+1)/2,
                      (-cos(hue-M_PI/3)+1)/2,
                      1);
    } else {
        return float4(0, 0, 0, 1);
    }
}

void computeStep(thread complex<float>& z, const complex<float> c, thread uint& alpha, thread uint& isComplete, uint maxAlpha, uint iter_step)
{
    uint limit = min(alpha + iter_step, maxAlpha);
    for (; alpha < limit; alpha += 1) {
        z = z*z + c;
        if (z.sqmag() > 4) {
            isComplete = 1;
            break;
        }
    }
}

uint convertToUInt(float num) {
    union {
        float input;
        uint output;
    } data;
    
    data.input = num;
    return data.output;
}

float convertToFloat(uint num) {
    union {
        uint input;
        float output;
    } data;
    
    data.input = num;
    return data.output;
}

/// Render a visualization of the Mandelbrot set into the `output` texture,
/// except, this time we will progressively render it in a higher resolution
/// over time.
kernel void mandelbrotShaderHighResolution(texture2d<float, access::write> output [[texture(0)]],
                                           texture2d<float, access::write> save [[texture(1)]],
                                           texture2d<float, access::read> open [[texture(2)]],
                                           const device uint2& state [[buffer(0)]],
                                           uint2 upos [[thread_position_in_grid]])
{
    uint width = output.get_width();
    uint height = output.get_height();
    if (upos.x > width || upos.y > height) return;
    
    float4 input = open.read(upos);
    complex<float> z = complex<float>(input.x, input.y);
    complex<float> c = screenToComplex<float>(upos.x - mandelbrotShiftX * width, upos.y, width, height);
    
    uint iterationCounter = convertToUInt(input.z);
    uint isComplete = convertToUInt(input.w);
    
    uint highestIteration = state[0];
    uint iterationStep = state[1];
    
    if (isComplete == 0) computeStep(z, c, iterationCounter, isComplete, highestIteration, iterationStep);
    
    float4 outbuf;
    outbuf.x = z._x;
    outbuf.y = z._y;
    outbuf.z = convertToFloat(iterationCounter);
    outbuf.w = convertToFloat(isComplete);
    
    save.write(outbuf, upos);
    output.write(colorPoint(z, iterationCounter, isComplete, highestIteration), upos);
}
