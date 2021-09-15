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

`include "RasterizerDefines.vh"

module RasteriCEr #(
    // The resolution of the whole screen
    parameter X_RESOLUTION = 128,
    parameter Y_RESOLUTION = 128,
    // The resolution of a subpart of the screen. The whole screen is constructed of 1 to n subparts.
    parameter Y_LINE_RESOLUTION = Y_RESOLUTION,

    // The bit width of the command stream interface
    // Allowed values: 32, 64, 128, 256 bit
    parameter CMD_STREAM_WIDTH = 16,

    // The bit width of the framebuffer stream interface
    parameter FRAMEBUFFER_STREAM_WIDTH = 16,

    // The size of the texture in bytes in power of two
    parameter TEXTURE_BUFFER_SIZE = 15
)
(
    input  wire         aclk,
    input  wire         resetn,

    // AXI Stream command interface
    input  wire         s_cmd_axis_tvalid,
    output wire         s_cmd_axis_tready,
    input  wire         s_cmd_axis_tlast,
    input  wire [CMD_STREAM_WIDTH - 1 : 0]  s_cmd_axis_tdata,

    // Framebuffer output
    // AXI Stream master interface
    output wire         m_framebuffer_axis_tvalid,
    input  wire         m_framebuffer_axis_tready,
    output wire         m_framebuffer_axis_tlast,
    output wire [FRAMEBUFFER_STREAM_WIDTH - 1 : 0]  m_framebuffer_axis_tdata,
    
    // Debug
    output wire [ 3:0]  dbgStreamState,
    output wire         dbgRasterizerRunning
);
    // The width of the frame buffer index (it would me nice if we could query the frame buffer instance directly ...)
    parameter FRAMEBUFFER_INDEX_WIDTH = $clog2(X_RESOLUTION * Y_LINE_RESOLUTION);

    // The bit width of the texture stream
`ifdef UP5K
    localparam TEXTURE_STREAM_WIDTH = 16;
`else 
    localparam TEXTURE_STREAM_WIDTH = CMD_STREAM_WIDTH;
`endif

    ///////////////////////////
    // Regs and wires
    ///////////////////////////
    // Texture access
    wire [31:0] texelIndex;
    wire [15:0] texel;
    wire [ 3:0] textureMode;

    // Color buffer access
    wire [FRAMEBUFFER_INDEX_WIDTH - 1 : 0] colorIndexRead;
    wire [FRAMEBUFFER_INDEX_WIDTH - 1 : 0] colorIndexWrite;
    wire        colorWriteEnable;
    wire [15:0] colorIn;
    wire [15:0] colorOut;

    // Depth buffer access
    wire [FRAMEBUFFER_INDEX_WIDTH - 1 : 0] depthIndexRead;
    wire [FRAMEBUFFER_INDEX_WIDTH - 1 : 0] depthIndexWrite;
    wire        depthWriteEnable;
    wire [15:0] depthIn;
    wire [15:0] depthOut;

    wire pixelInPipeline;
   
    // Control
    wire        rasterizerRunning;
    wire        s_rasterizer_axis_tvalid;
    wire        s_rasterizer_axis_tready;
    wire        s_rasterizer_axis_tlast;
    wire [CMD_STREAM_WIDTH - 1 : 0] s_rasterizer_axis_tdata;

    // Memory
    wire        colorBufferApply;
    wire        colorBufferApplied;
    wire        colorBufferCmdCommit;
    wire        colorBufferCmdMemset;
    wire [15:0] confColorBufferClearColor;
    wire        depthBufferApply;
    wire        depthBufferApplied;
    wire        depthBufferCmdCommit;
    wire        depthBufferCmdMemset;
    wire [15:0] confDepthBufferClearDepth;

    // Texture memory AXIS
    wire        s_texture_axis_tvalid;
    wire        s_texture_axis_tready;
    wire        s_texture_axis_tlast;
    wire [TEXTURE_STREAM_WIDTH - 1 : 0] s_texture_axis_tdata;

    // Shader
    wire        m_fragment_axis_tvalid;
    wire        m_fragment_axis_tready;
    wire        m_fragment_axis_tlast;
    wire [FRAMEBUFFER_INDEX_WIDTH + RASTERIZER_AXIS_PARAMETER_SIZE - 1 : 0] m_fragment_axis_tdata;
    wire [15:0] confReg1;
    wire [15:0] confReg2;
    wire [15:0] confTextureEnvColor;

    assign dbgRasterizerRunning = rasterizerRunning;

    CommandParser commandParser(
        .aclk(aclk),
        .resetn(resetn),

        // AXI Stream command interface
        .s_cmd_axis_tvalid(s_cmd_axis_tvalid),
        .s_cmd_axis_tready(s_cmd_axis_tready),
        .s_cmd_axis_tlast(s_cmd_axis_tlast),
        .s_cmd_axis_tdata(s_cmd_axis_tdata),

        // Rasterizer
        // Configs
        .confTextureMode(textureMode),
        .confReg1(confReg1),
        .confReg2(confReg2),
        .confTextureEnvColor(confTextureEnvColor),
        // Control
        .rasterizerRunning(rasterizerRunning),
        .pixelInPipeline(pixelInPipeline),
        .m_rasterizer_axis_tvalid(s_rasterizer_axis_tvalid),
        .m_rasterizer_axis_tready(s_rasterizer_axis_tready),
        .m_rasterizer_axis_tlast(s_rasterizer_axis_tlast),
        .m_rasterizer_axis_tdata(s_rasterizer_axis_tdata),

        // applied
        .colorBufferApply(colorBufferApply),
        .colorBufferApplied(colorBufferApplied),
        .colorBufferCmdCommit(colorBufferCmdCommit),
        .colorBufferCmdMemset(colorBufferCmdMemset),
        .confColorBufferClearColor(confColorBufferClearColor),
        .depthBufferApply(depthBufferApply),
        .depthBufferApplied(depthBufferApplied),
        .depthBufferCmdCommit(depthBufferCmdCommit),
        .depthBufferCmdMemset(depthBufferCmdMemset),
        .confDepthBufferClearDepth(confDepthBufferClearDepth),

        // Texture AXIS interface
        .m_texture_axis_tvalid(s_texture_axis_tvalid),
        .m_texture_axis_tready(s_texture_axis_tready),
        .m_texture_axis_tlast(s_texture_axis_tlast),
        .m_texture_axis_tdata(s_texture_axis_tdata),

        // Debug
        .dbgStreamState(dbgStreamState)
    );
    defparam commandParser.CMD_STREAM_WIDTH = CMD_STREAM_WIDTH;
    defparam commandParser.TEXTURE_STREAM_WIDTH = TEXTURE_STREAM_WIDTH;

    ///////////////////////////
    // Modul Instantiation and wiring
    ///////////////////////////
    TextureBuffer texCache (
        .clk(aclk),
        .reset(!resetn),
        .mode(textureMode),

        .s_axis_tvalid(s_texture_axis_tvalid),
        .s_axis_tready(s_texture_axis_tready),
        .s_axis_tlast(s_texture_axis_tlast),
        .s_axis_tdata(s_texture_axis_tdata),

        .texel(texel),
        .texelIndex(texelIndex)
    );
    defparam texCache.STREAM_WIDTH = TEXTURE_STREAM_WIDTH;
    defparam texCache.SIZE = TEXTURE_BUFFER_SIZE;

    FrameBuffer depthBuffer (  
        .clk(aclk),
        .reset(!resetn),

        .fragIndexRead(depthIndexRead),
        .fragOut(depthIn),
        .fragIndexWrite(depthIndexWrite),
        .fragIn(depthOut),
        .fragWriteEnable(depthWriteEnable),
        .fragMask({4{confReg1[REG1_DEPTH_MASK_POS +: REG1_DEPTH_MASK_SIZE]}}),
        
        .apply(depthBufferApply),
        .applied(depthBufferApplied),
        .cmdCommit(depthBufferCmdCommit),
        .cmdMemset(depthBufferCmdMemset),

        .m_axis_tvalid(),
        .m_axis_tready(1'b1),
        .m_axis_tlast(),
        .m_axis_tdata(),

        .clearColor(confDepthBufferClearDepth)
    );
    defparam depthBuffer.FRAME_SIZE = X_RESOLUTION * Y_LINE_RESOLUTION;
    defparam depthBuffer.STREAM_WIDTH = FRAMEBUFFER_STREAM_WIDTH;

    FrameBuffer colorBuffer (  
        .clk(aclk),
        .reset(!resetn),

        .fragIndexRead(colorIndexRead),
        .fragOut(colorIn),
        .fragIndexWrite(colorIndexWrite),
        .fragIn(colorOut),
        .fragWriteEnable(colorWriteEnable),
        .fragMask({ confReg1[REG1_COLOR_MASK_R_POS +: REG1_COLOR_MASK_R_SIZE], 
                    confReg1[REG1_COLOR_MASK_G_POS +: REG1_COLOR_MASK_G_SIZE], 
                    confReg1[REG1_COLOR_MASK_B_POS +: REG1_COLOR_MASK_B_SIZE], 
                    confReg1[REG1_COLOR_MASK_A_POS +: REG1_COLOR_MASK_A_SIZE]}),
        
        .apply(colorBufferApply),
        .applied(colorBufferApplied),
        .cmdCommit(colorBufferCmdCommit),
        .cmdMemset(colorBufferCmdMemset),

        .m_axis_tvalid(m_framebuffer_axis_tvalid),
        .m_axis_tready(m_framebuffer_axis_tready),
        .m_axis_tlast(m_framebuffer_axis_tlast),
        .m_axis_tdata(m_framebuffer_axis_tdata),

        .clearColor(confColorBufferClearColor)
    );
    defparam colorBuffer.FRAME_SIZE = X_RESOLUTION * Y_LINE_RESOLUTION;
    defparam colorBuffer.STREAM_WIDTH = FRAMEBUFFER_STREAM_WIDTH;

    Rasterizer rop (
        .clk(aclk), 
        .reset(!resetn), 

        .rasterizerRunning(rasterizerRunning),

        .s_axis_tvalid(s_rasterizer_axis_tvalid),
        .s_axis_tready(s_rasterizer_axis_tready),
        .s_axis_tlast(s_rasterizer_axis_tlast),
        .s_axis_tdata(s_rasterizer_axis_tdata),

        .m_axis_tvalid(m_fragment_axis_tvalid),
        .m_axis_tready(m_fragment_axis_tready),
        .m_axis_tlast(m_fragment_axis_tlast),
        .m_axis_tdata(m_fragment_axis_tdata)
    );
    defparam rop.X_RESOLUTION = X_RESOLUTION;
    defparam rop.Y_RESOLUTION = Y_RESOLUTION;
    defparam rop.Y_LINE_RESOLUTION = Y_LINE_RESOLUTION;
    defparam rop.FRAMEBUFFER_INDEX_WIDTH = FRAMEBUFFER_INDEX_WIDTH;
    defparam rop.CMD_STREAM_WIDTH = CMD_STREAM_WIDTH;

`ifdef UP5K
    FragmentPipelineIce40Wrapper fragmentPipeline (    
`else
    FragmentPipeline fragmentPipeline (    
`endif
        .clk(aclk),
        .reset(!resetn),
        .pixelInPipeline(pixelInPipeline),

        .confReg1(confReg1),
        .confReg2(confReg2),
        .confTextureEnvColor(confTextureEnvColor),

        .s_axis_tvalid(m_fragment_axis_tvalid),
        .s_axis_tready(m_fragment_axis_tready),
        .s_axis_tlast(m_fragment_axis_tlast),
        .s_axis_tdata(m_fragment_axis_tdata),

        .texelIndex(texelIndex),
        .texel(texel),

        .colorIndexRead(colorIndexRead),
        .colorIn(colorIn),
        .colorIndexWrite(colorIndexWrite),
        .colorWriteEnable(colorWriteEnable),
        .colorOut(colorOut),

        .depthIndexRead(depthIndexRead),
        .depthIn(depthIn),
        .depthIndexWrite(depthIndexWrite),
        .depthWriteEnable(depthWriteEnable),
        .depthOut(depthOut)
    );
    defparam fragmentPipeline.FRAMEBUFFER_INDEX_WIDTH = FRAMEBUFFER_INDEX_WIDTH;

endmodule