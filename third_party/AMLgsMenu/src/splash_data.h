#pragma once

#include <cstddef>
#include <cstdint>

inline constexpr int kSplashWidth = 448;
inline constexpr int kSplashHeight = 448;
inline constexpr int kSplashFrameCount = 40;

struct SplashFrameRecord
{
    uint32_t offset;
    uint32_t length;
    uint32_t uncompressed_length;
};

extern const int kSplashFrameDelayMs[kSplashFrameCount];
extern const SplashFrameRecord kSplashFrameRecords[kSplashFrameCount];
extern const unsigned char kSplashCompressedData[];
extern const std::size_t kSplashCompressedDataSize;
