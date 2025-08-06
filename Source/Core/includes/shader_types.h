#pragma once

#include <cstdint>

#include "matrix.h"

namespace
{
   // Remove these attributes
   #define row_major
   #define column_major

   typedef uint32_t uint;

   struct uint2
   {
      uint x;
      uint y;

      friend bool operator==(const uint2& lhs, const uint2& rhs)
      {
         return lhs.x == rhs.x && lhs.y == rhs.y;
      }
   };

   struct uint3
   {
      uint x;
      uint y;
      uint z;

      friend bool operator==(const uint3& lhs, const uint3& rhs)
      {
         return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z;
      }
   };

   struct uint4
   {
      uint x;
      uint y;
      uint z;
      uint w;

      friend bool operator==(const uint4& lhs, const uint4& rhs)
      {
         return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs.w == rhs.w;
      }
   };

   struct float2
   {
      float x;
      float y;

      friend bool operator==(const float2& lhs, const float2& rhs)
      {
         return lhs.x == rhs.x && lhs.y == rhs.y;
      }
   };

   struct float3
   {
      float x;
      float y;
      float z;

      friend bool operator==(const float3& lhs, const float3& rhs)
      {
         return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z;
      }
   };

   struct float4
   {
      float x;
      float y;
      float z;
      float w;

      friend bool operator==(const float4& lhs, const float4& rhs)
      {
         return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs.w == rhs.w;
      }
   };

   typedef Math::Matrix44F float4x4;
   static_assert(sizeof(Math::Matrix44F) == sizeof(float4) * 4);
}