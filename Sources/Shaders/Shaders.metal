#include <metal_stdlib>

namespace fg {
    /// Basic implementation of complex numbers, with * + - operators, and a function to return the squared magnitude.
    struct complex {
        
        float real;
        float imag;
        
        complex(float r, float i) : real(r), imag(i) { }
        
        float sqmag() const {
            return real*real + imag*imag;
        }
        
        complex operator*(const thread complex& other) const {
            // (a + bi)(x + yi)
            // ax + bxi + ayi - by
            // ax - by + (bx + ay)i
            
            float r = real * other.real - imag * other.imag;
            float i = imag * other.real + real * other.imag;
            return complex(r, i);
        }
        
        complex operator+(const thread complex& other) const {
            float r = real + other.real;
            float i = imag + other.imag;
            return complex(r, i);
        }
        
        complex operator-(const thread complex& other) const {
            float r = real - other.real;
            float i = imag - other.imag;
            return complex(r, i);
        }
        
        complex operator/(const thread complex& other) const {
            // (a + bi) / (x + yi)
            // (a + bi) * (x - yi) / (x + yi) * (x - yi)
            // (a + bi) * (x - yi) / (x*x + xyi - xyi + y*y)
            // (a + bi) * (x - yi) / (x*x + y*y)
            // (a*x + xbi - ayi + by) / (x*x + y*y)
            // (ax + by + (xb - ay)i) / (xx + yy)
            
            float m = other.sqmag();
            float r = (real * other.real + imag * other.imag) / m;
            float i = (other.real * imag - real * other.imag) / m;
            return complex(r, i);
        }
        
        complex operator*(const thread float& c) const {
            return complex(real * c, imag * c);
        }
    };
}

// ------------------------------------------------------------------------------
// Over-time Rendering
// ------------------------------------------------------------------------------

template<typename A, typename B> B binaryCast(A num)
{
    union {
        A input;
        B output;
    } data;
    
    data.input = num;
    return data.output;
}

using fg::complex;
using metal::uint;
using metal::uint2;
using metal::float4;
using metal::log2;
using metal::log10;
using metal::cos;
using metal::texture2d;
using metal::access;
using metal::min;

void computeStep(thread complex& z,
                 const complex c,
                 thread uint& iterationCounter,
                 thread uint& isComplete,
                 uint highestIteration,
                 uint iterationStep)
{
    uint limit = min(iterationCounter + iterationStep, highestIteration);
    for (; iterationCounter < limit; iterationCounter += 1) {
        z = z*z + c;
        if (z.sqmag() > 4) {
            isComplete = 1;
            break;
        }
    }
}

float4 colorPoint(complex z, uint i, uint isComplete, uint highestIteration) {
    if (isComplete == 0) return float4(0, 0, 0, 1);
    
    float hue = (i+1-log2(log10(z.sqmag())/2))/highestIteration*4 * M_PI_F + 3;
    
    // Convert to RGB
    return float4((cos(hue)+1)/2,
                  (-cos(hue+M_PI_F/3)+1)/2,
                  (-cos(hue-M_PI_F/3)+1)/2,
                  1);
}

/// Convert a point on the screen to a point in the complex plane.
complex cartesianPlaneToArgandDiagram(float x,
                                      float y,
                                      float width,
                                      float height,
                                      const device uint* corners)
{
    float topLeftReal = binaryCast<uint, float>(corners[0]);
    float topLeftImag = binaryCast<uint, float>(corners[1]);
    float bottomRightReal = binaryCast<uint, float>(corners[2]);
    float bottomRightImag = binaryCast<uint, float>(corners[3]);
    
    float real = topLeftReal + (x / width) * (bottomRightReal - topLeftReal);
    float imag = topLeftImag + (y / height) * (bottomRightImag - topLeftImag);
    return complex(real, imag);
}

struct __attribute__((packed)) Arguments  {
    uint currentFrame;
    uint iterationsPerFrame;
    float topLeftReal;
    float topLeftImag;
    float bottomRightReal;
    float bottomRightImag;
};

struct __attribute__((packed)) PackedComplexNumber {
    float real;
    float imag;
};

struct __attribute__((packed)) Stack {
    PackedComplexNumber z;
    uint iterationsPerformed;
    uint isComplete;
    
    Stack(float4 buff) {
        z.real = buff.x;
        z.imag = buff.y;
        iterationsPerformed = binaryCast<float4, uint>(buff.z);
        isComplete = binaryCast<float4, uint>(buff.w);
    }
};

/// Render a visualization of the Mandelbrot set into the `output` texture,
/// except, this time we will progressively render it in a higher resolution
/// over time.
kernel void mandelbrotShaderHighResolution(texture2d<float, access::write> output [[texture(0)]],
                                           texture2d<float, access::write> save [[texture(1)]],
                                           texture2d<float, access::read> open [[texture(2)]],
                                           const device uint* state [[buffer(0)]],
                                           uint2 upos [[thread_position_in_grid]])
{
    uint width = output.get_width();
    uint height = output.get_height();
    if (upos.x > width || upos.y > height) return;
    
    float4 input = open.read(upos);
    
    uint highestIteration = state[0];
    uint iterationStep = state[1];
    uint iterationCounter = binaryCast<float, uint>(input.z);
    uint isComplete = binaryCast<float, uint>(input.w);
    
    complex z = complex(input.x, input.y);
    complex c = cartesianPlaneToArgandDiagram(upos.x, upos.y,
                                              width, height,
                                              state+2);
    
    if (isComplete == 0) computeStep(z, c, iterationCounter, isComplete, highestIteration, iterationStep);
    
    float4 outbuf;
    outbuf.x = z.real;
    outbuf.y = z.imag;
    outbuf.z = binaryCast<uint, float>(iterationCounter);
    outbuf.w = binaryCast<uint, float>(isComplete);
    
    save.write(outbuf, upos);
    output.write(colorPoint(z, iterationCounter, isComplete, highestIteration), upos);
}

kernel void scroller(texture2d<float, access::write> output [[texture(0)]],
                     texture2d<float, access::read> open [[texture(1)]],
                     const device uint* state [[buffer(0)]],
                     uint2 upos [[thread_position_in_grid]])
{
    uint width = output.get_width();
    uint height = output.get_height();
    if (upos.x > width || upos.y > height) return;
    
    float4 input = open.read(upos);
    
    uint highestIteration = 200;
    uint iterationStep = 200;
    uint iterationCounter = 0;
    uint isComplete = 0;
    
    complex z = complex(input.x, input.y);
    complex c = cartesianPlaneToArgandDiagram(upos.x, upos.y,
                                              width, height,
                                              state+2);
    
    computeStep(z, c, iterationCounter, isComplete, highestIteration, iterationStep);
    output.write(colorPoint(z, iterationCounter, isComplete, highestIteration), upos);
}
