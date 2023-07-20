// Copyright (c) 2017 Ollix
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// ---
// Author: olliwang@ollix.com (Olli Wang)

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

typedef struct {
  float2 pos [[attribute(0)]];
  float2 tcoord [[attribute(1)]];
} Vertex;

typedef struct {
  float4 pos  [[position]];
  float2 fpos;
  float2 ftcoord;
} RasterizerData;

typedef struct  {
  float3x3 scissorMat;
  float3x3 paintMat;
  float4 innerCol;
  float4 outerCol;
  float2 scissorExt;
  float2 scissorScale;
  float2 extent;
  float radius;
  float feather;
  float strokeMult;
  float strokeThr;
  int texType;
  int type;
  int multStopEnabled;
  int stopsCount;
  int cycleMethod;
  int interpolation;
  float stops[16];
  float4 colors[16];
} Uniforms;

float4 decodeColor(constant Uniforms& uniforms, int index);
float decodeStop(constant Uniforms& uniforms, int index);
float4 decodeMix(constant Uniforms& uniforms, float4 a, float4 b, float t);

float scissorMask(constant Uniforms& uniforms, float2 p);
float sdroundrect(constant Uniforms& uniforms, float2 pt);
float strokeMask(constant Uniforms& uniforms, float2 ftcoord);

float4 decodeColor(constant Uniforms& uniforms, int index) {
  int cIndex = index >= uniforms.stopsCount ? (uniforms.stopsCount - 1) : index;
  return uniforms.colors[cIndex];
}
float decodeStop(constant Uniforms& uniforms, int index) {
  int cIndex = index >= uniforms.stopsCount ? (uniforms.stopsCount - 1) : index;
  return uniforms.stops[cIndex];
}
float4 decodeMix(constant Uniforms& uniforms, float4 a, float4 b, float t) {
  t = clamp(t, 0.0, 1.0);
  if (uniforms.interpolation == 1) t = sqrt(1 - (1 - t) * (1 - t)); 
  else if (uniforms.interpolation == 2) t = 1 - sqrt(1 - t * t); 
  else if (uniforms.interpolation == 3) t = t * t * t * (t * (t * 6 - 15) + 10); 
  return mix(a, b, t);
}

float scissorMask(constant Uniforms& uniforms, float2 p) {
  float2 sc = (abs((uniforms.scissorMat * float3(p, 1.0f)).xy)
                  - uniforms.scissorExt) \
              * uniforms.scissorScale;
  sc = saturate(float2(0.5f) - sc);
  return sc.x * sc.y;
}

float sdroundrect(constant Uniforms& uniforms, float2 pt) {
  float2 ext2 = uniforms.extent - float2(uniforms.radius);
  float2 d = abs(pt) - ext2;
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - uniforms.radius;
}

float strokeMask(constant Uniforms& uniforms, float2 ftcoord) {
  return min(1.0, (1.0 - abs(ftcoord.x * 2.0 - 1.0)) * uniforms.strokeMult) \
         * min(1.0, ftcoord.y);
}

// Vertex Function
vertex RasterizerData vertexShader(Vertex vert [[stage_in]],
                                   constant float2& viewSize [[buffer(1)]]) {
  RasterizerData out;
  out.ftcoord = vert.tcoord;
  out.fpos = vert.pos;
  out.pos = float4(2.0 * vert.pos.x / viewSize.x - 1.0,
                   1.0 - 2.0 * vert.pos.y / viewSize.y,
                   0, 1);
  return out;
}

// Fragment function (No AA)
fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               constant Uniforms& uniforms [[buffer(0)]],
                               texture2d<float> texture [[texture(0)]],
                               sampler sampler [[sampler(0)]]) {
  float scissor = scissorMask(uniforms, in.fpos);
  if (scissor == 0)
    return float4(0);

  if (uniforms.type == 0) {  // MNVG_SHADER_FILLGRAD
    float2 pt = (uniforms.paintMat * float3(in.fpos, 1.0)).xy;
    float d = clamp(saturate((uniforms.feather * 0.5 + sdroundrect(uniforms, pt)) / uniforms.feather), 0.0, 1.0);
    
    float4 color;
    
    // Multstop gradient
    if (uniforms.multStopEnabled == 1) 
    {
      if (uniforms.cycleMethod == 1) // reflect
        d = d - floor(d);
      else if (uniforms.cycleMethod == 2) // repeat
        d = (int(floor(d)) % 2 == 0) ? d - floor(d) : 1 - (d - floor(d));
      
      float prevStop = 0;
      float stop = 0;
      int stopIdx = 0;
      
      for (; stopIdx < uniforms.stopsCount; stopIdx++)
      {
        prevStop = stop;
        stop = decodeStop(uniforms, stopIdx);
        if (d <= stop)
          break;
      }
      
      if (stopIdx == 0)
      {
        color = decodeColor(uniforms, 0);
      }
      else if (stopIdx == uniforms.stopsCount)
      {
        color = decodeColor(uniforms, uniforms.stopsCount - 1);
      }
      else
      {
        float colorPos = 0;
        
        if (stop - prevStop > 0)
        {
          colorPos = clamp((d - prevStop) / (stop - prevStop), 0.0, 1.0);
        }
        
        color = decodeMix(uniforms, decodeColor(uniforms, stopIdx - 1), decodeColor(uniforms, stopIdx), colorPos);
      }
    }
    else 
    {
      color = mix(uniforms.innerCol, uniforms.outerCol, d);
    }
    
    return color * scissor;
  } else if (uniforms.type == 1) {  // MNVG_SHADER_FILLIMG
    float2 pt = (uniforms.paintMat * float3(in.fpos, 1.0)).xy / uniforms.extent;
    float4 color = texture.sample(sampler, pt);
    if (uniforms.texType == 1)
      color = float4(color.xyz * color.w, color.w);
    else if (uniforms.texType == 2)
      color = float4(color.x);
    color *= scissor;
    return color * uniforms.innerCol;
  } else {  // MNVG_SHADER_IMG
    float4 color = texture.sample(sampler, in.ftcoord);
    if (uniforms.texType == 1)
      color = float4(color.xyz * color.w, color.w);
    else if (uniforms.texType == 2)
      color = float4(color.x);
    color *= scissor;
    return color * uniforms.innerCol;
  }
}

// Fragment function (AA)
fragment float4 fragmentShaderAA(RasterizerData in [[stage_in]],
                                 constant Uniforms& uniforms [[buffer(0)]],
                                 texture2d<float> texture [[texture(0)]],
                                 sampler sampler [[sampler(0)]]) {
  float scissor = scissorMask(uniforms, in.fpos);
  if (scissor == 0)
    return float4(0);

  if (uniforms.type == 2) {  // MNVG_SHADER_IMG
    float4 color = texture.sample(sampler, in.ftcoord);
    if (uniforms.texType == 1)
      color = float4(color.xyz * color.w, color.w);
    else if (uniforms.texType == 2)
      color = float4(color.x);
    color *= scissor;
    return color * uniforms.innerCol;
  }

  float strokeAlpha = strokeMask(uniforms, in.ftcoord);
  if (strokeAlpha < uniforms.strokeThr) {
    return float4(0);
  }

  if (uniforms.type == 0) {  // MNVG_SHADER_FILLGRAD
    float2 pt = (uniforms.paintMat * float3(in.fpos, 1.0)).xy;
    float d = clamp(saturate((uniforms.feather * 0.5 + sdroundrect(uniforms, pt)) / uniforms.feather), 0.0, 1.0);
    
    float4 color;
    
    // Multstop gradient
    if (uniforms.multStopEnabled == 1) 
    {
      if (uniforms.cycleMethod == 1) // reflect
        d = d - floor(d);
      else if (uniforms.cycleMethod == 2) // repeat
        d = (int(floor(d)) % 2 == 0) ? d - floor(d) : 1 - (d - floor(d));
      
      float prevStop = 0;
      float stop = 0;
      int stopIdx = 0;
      
      for (; stopIdx < uniforms.stopsCount; stopIdx++)
      {
        prevStop = stop;
        stop = decodeStop(uniforms, stopIdx);
        if (d <= stop)
          break;
      }
      
      if (stopIdx == 0)
      {
        color = decodeColor(uniforms, 0);
      }
      else if (stopIdx == uniforms.stopsCount)
      {
        color = decodeColor(uniforms, uniforms.stopsCount - 1);
      }
      else
      {
        float colorPos = 0;
        
        if (stop - prevStop > 0)
        {
          colorPos = clamp((d - prevStop) / (stop - prevStop), 0.0, 1.0);
        }
        
        color = decodeMix(uniforms, decodeColor(uniforms, stopIdx - 1), decodeColor(uniforms, stopIdx), colorPos);
      }
    }
    else 
    {
      color = mix(uniforms.innerCol, uniforms.outerCol, d);
    }
    
    color *= scissor;
    color *= strokeAlpha;
    return color;
  } else {  // MNVG_SHADER_FILLIMG
    float2 pt = (uniforms.paintMat * float3(in.fpos, 1.0)).xy / uniforms.extent;
    float4 color = texture.sample(sampler, pt);
    if (uniforms.texType == 1)
      color = float4(color.xyz * color.w, color.w);
    else if (uniforms.texType == 2)
      color = float4(color.x);
    color *= scissor;
    color *= strokeAlpha;
    return color * uniforms.innerCol;
  }
}
