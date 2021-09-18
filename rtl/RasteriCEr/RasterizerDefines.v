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

`ifndef RASTERIZER_UNIT_DEFINES_V_
`define RASTERIZER_UNIT_DEFINES_V_

parameter RASTERIZER_AXIS_TEXTURE_S_POS = 0;
parameter RASTERIZER_AXIS_TEXTURE_S_SIZE = 32;
parameter RASTERIZER_AXIS_TEXTURE_T_POS = RASTERIZER_AXIS_TEXTURE_S_POS + RASTERIZER_AXIS_TEXTURE_S_SIZE;
parameter RASTERIZER_AXIS_TEXTURE_T_SIZE = 32;
parameter RASTERIZER_AXIS_DEPTH_W_POS = RASTERIZER_AXIS_TEXTURE_T_POS + RASTERIZER_AXIS_TEXTURE_T_SIZE;
parameter RASTERIZER_AXIS_DEPTH_W_SIZE = 32;
parameter RASTERIZER_AXIS_TRIANGLE_COLOR_POS = RASTERIZER_AXIS_DEPTH_W_POS + RASTERIZER_AXIS_DEPTH_W_SIZE;
parameter RASTERIZER_AXIS_TRIANGLE_COLOR_SIZE = 16;
parameter RASTERIZER_AXIS_PARAMETER_SIZE = RASTERIZER_AXIS_TEXTURE_S_SIZE 
                            + RASTERIZER_AXIS_TEXTURE_T_SIZE 
                            + RASTERIZER_AXIS_DEPTH_W_SIZE 
                            + RASTERIZER_AXIS_TRIANGLE_COLOR_SIZE;

`endif // RASTERIZER_UNIT_DEFINES_V_
