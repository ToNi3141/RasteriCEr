// RasteriCEr
// https://github.com/ToNi3141/RasteriCEr
// Copyright (c) 2021 ToNi3141

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#ifndef VEC_HPP
#define VEC_HPP
#include <array>
#include <math.h>

template <uint8_t VecSize>
class Vec
{
public:
    Vec() {}
    Vec(const Vec<VecSize>& val) { operator=(val.vec); }
    Vec(const std::array<float, VecSize>& val) { operator=(val); }
    Vec(const float* val) { operator=(val); }
    ~Vec() {}

    void initHomogeneous()
    {
        for (uint32_t i = 0; i < VecSize - 1; i++)
            vec[i] = 0.0f;
        vec[VecSize - 1] = 1.0f;
    }

    template <typename T>
    void fromArray(const T* arr, const uint8_t size)
    {
        const uint32_t len = std::min(size, VecSize);
        for (uint8_t i = 0; i < len; i++)
            vec[i] = arr[i];
    }

    Vec<VecSize>& operator*= (const float val)
    {
        mul(val);
        return *this;
    }

    Vec<VecSize>& operator*= (const Vec<VecSize>& val)
    {
        mul(val);
        return *this;
    }

    void div(float val)
    {
        for (uint32_t i = 0; i < VecSize; i++)
            vec[i] = vec[i] / val;
    }

    void mul(float val)
    {
        for (uint32_t i = 0; i < VecSize; i++)
            vec[i] = vec[i] * val;
    }

    void mul(const Vec<VecSize>& val)
    {
        for (uint32_t i = 0; i < VecSize; i++)
            vec[i] = vec[i] * val[i];
    }

    Vec<VecSize>& operator+= (const Vec<VecSize>& val)
    {
        for (uint32_t i = 0; i < VecSize; i++)
            vec[i] += val[i];
        return *this;
    }

    Vec<VecSize>& operator-= (const Vec<VecSize>& val)
    {
        for (uint32_t i = 0; i < VecSize; i++)
            vec[i] -= val[i];
        return *this;
    }

    Vec<VecSize>& operator-= (float val)
    {
        for (uint32_t i = 0; i < VecSize; i++)
            vec[i] -= val;
        return *this;
    }

    float& operator[] (int index) { return vec[index]; }
    float operator[] (int index) const { return vec[index]; }
    void operator= (const std::array<float, VecSize>& val) { vec = val; }
    void operator= (const float* val)
    {
        for (uint32_t i = 0; i < VecSize; i++)
            vec[i] = val[i];
    }

    float dot(const Vec<VecSize>& val) const
    {
        float retVal = 0;
        for (uint32_t i = 0; i < VecSize; i++)
            retVal += vec[i] * val[i];
        return retVal;
    }

    void normalize()
    {
        float tmp = 0;
        for (uint32_t i = 0; i < VecSize; i++)
            tmp += vec[i] * vec[i];

        tmp = sqrtf(tmp);
        if (tmp == 0.0f)
            return;

        tmp = 1.0f / tmp;
        for (uint32_t i = 0; i < VecSize; i++)
            vec[i] = vec[i] * tmp;

    }

    float dist(const Vec<VecSize>& val)
    {
        float tmp = 0;
        for (uint32_t i = 0; i < VecSize; i++)
            tmp += (vec[i] - val[i]) * (vec[i] - val[i]);
        return sqrtf(tmp);
    }

    void unit()
    {
        float tmp = 0;
        for (uint32_t i = 0; i < VecSize; i++)
            tmp += vec[i] * vec[i];

        tmp = sqrtf(tmp);
        if (tmp == 0.0f)
            return;

        tmp = 1.0f / tmp;
        for (uint32_t i = 0; i < VecSize; i++)
            vec[i] = vec[i] * tmp;
    }

    void cross(const Vec<VecSize>& val)
    {
        const Vec<VecSize> tmp{*this};
        for (uint8_t i = 0; i < VecSize; i++)
        {
            vec[i] = (tmp[(i + 1) % VecSize] * val[(i + 2) % VecSize]) - (tmp[(i + 2) % VecSize] * val[(i + 1) % VecSize]);
        }
    }

    std::array<float, VecSize> vec;
};

template <uint8_t S, uint8_t T>
inline Vec<T> operator *(const Vec<S>& lhs, const Vec<T>& rhs)
{
    Vec<T> tmp{rhs};
    tmp *= lhs;
    return tmp;
}

template <uint8_t T>
inline Vec<T> operator -(const Vec<T>& lhs, const Vec<T>& rhs)
{
    Vec<T> tmp{lhs};
    tmp -= rhs;
    return tmp;
}

template <uint8_t T>
inline Vec<T> operator +(const Vec<T>& lhs, const Vec<T>& rhs)
{
    Vec<T> tmp{lhs};
    tmp += rhs;
    return tmp;
}

using Vec2 = Vec<2>;
using Vec3 = Vec<3>;
using Vec4 = Vec<4>;

#endif // VECI_HPP
