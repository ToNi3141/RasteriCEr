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

`include "RegisterAndDescriptorDefines.vh"

module CommandParser #(
    parameter CMD_STREAM_WIDTH = 16,
    parameter TEXTURE_STREAM_WIDTH = 16
) (
    input  wire         aclk,
    input  wire         resetn,

    // AXI Stream command interface
    input  wire         s_cmd_axis_tvalid,
    output reg          s_cmd_axis_tready,
    input  wire         s_cmd_axis_tlast,
    input  wire [CMD_STREAM_WIDTH - 1 : 0]  s_cmd_axis_tdata,

    // Rasterizer
    // Configs
    output reg  [ 3:0]  confTextureMode,
    output wire [15:0]  confReg1,
    output wire [15:0]  confReg2,
    output wire [15:0]  confTextureEnvColor,
    // Control
    input  wire         rasterizerRunning,
    input  wire         pixelInPipeline,
    output reg          m_rasterizer_axis_tvalid,
    input  wire         m_rasterizer_axis_tready,
    output reg          m_rasterizer_axis_tlast,
    output reg  [CMD_STREAM_WIDTH - 1 : 0]  m_rasterizer_axis_tdata,

    // Color/Depth buffer control
    output reg          colorBufferApply,
    input  wire         colorBufferApplied,
    output reg          colorBufferCmdCommit,
    output reg          colorBufferCmdMemset,
    output wire [15:0]  confColorBufferClearColor,
    output reg          depthBufferApply,
    input  wire         depthBufferApplied,
    output reg          depthBufferCmdCommit,
    output reg          depthBufferCmdMemset,
    output wire [15:0]  confDepthBufferClearDepth,

    // Texture stream interface
    output reg          m_texture_axis_tvalid,
    input  wire         m_texture_axis_tready,
    output reg          m_texture_axis_tlast,
    output reg  [TEXTURE_STREAM_WIDTH - 1 : 0]  m_texture_axis_tdata,

    // Debug
    output wire [ 3 : 0]  dbgStreamState
);
    localparam DATABUS_SCALE_FACTOR = (CMD_STREAM_WIDTH / 8);
    localparam DATABUS_SCALE_FACTOR_LOG2 = $clog2(DATABUS_SCALE_FACTOR);

    // Command Interface Statemachine
    localparam WAIT_FOR_IDLE = 5'd0;
    localparam COMMAND_IN = 5'd1;
    localparam EXEC_TRIANGLE_STREAM = 5'd2;
    localparam EXEC_TEXTURE_STREAM = 5'd3;
    localparam EXEC_RENDER_CONFIG = 5'd4;
    localparam EXEC_TEXTURE_STREAM_16 = 5'd5;

    // Wait For Rasterizer Statemachine
    localparam RASTERIZER_CONTROL_WAITFORCOMMAND = 0;
    localparam RASTERIZER_CONTROL_WAITFOREND = 1;

    // Wait For Cache Apply Statemachine
    localparam FB_CONTROL_WAITFORCOMMAND = 0;
    localparam FB_CONTROL_WAITFOREND = 1;

    // Command Unit Variables
    reg  [15 : 0]   configReg[0 : 4];
    reg             apply;
    wire            applied;
    reg  [13 : 0]   streamCounter;
    reg             parameterComplete;

    // Local Statemachine variables
    reg  [ 4 : 0]   state;
    reg  [ 1 : 0]   rasterizerControlState;
    reg  [ 1 : 0]   fbControlState;
    reg             wlsp = 0;

    assign applied = colorBufferApplied & depthBufferApplied;
    assign confColorBufferClearColor = configReg[OP_RENDER_CONFIG_COLOR_BUFFER_CLEAR_COLOR];
    assign confDepthBufferClearDepth = configReg[OP_RENDER_CONFIG_DEPTH_BUFFER_CLEAR_DEPTH];
    assign confReg1 = configReg[OP_RENDER_CONFIG_REG1];
    assign confReg2 = configReg[OP_RENDER_CONFIG_REG2];
    assign confTextureEnvColor = configReg[OP_RENDER_CONFIG_TEX_ENV_COLOR];

    assign dbgStreamState = state[3:0];

    always @(posedge aclk)
    begin
        if (!resetn)
        begin
            state <= WAIT_FOR_IDLE;
            
            rasterizerControlState <= RASTERIZER_CONTROL_WAITFORCOMMAND;

            fbControlState <= FB_CONTROL_WAITFORCOMMAND;
            apply <= 0;
            s_cmd_axis_tready <= 0;

            m_texture_axis_tvalid <= 0;
            m_texture_axis_tlast <= 0;
            
            m_rasterizer_axis_tvalid <= 0;
            m_rasterizer_axis_tlast <= 0;
        end
        else 
        begin
            case (state)
            WAIT_FOR_IDLE:
            begin
                m_rasterizer_axis_tlast <= 0;
                m_rasterizer_axis_tvalid <= 0;
                m_texture_axis_tvalid <= 0;
                m_texture_axis_tlast <= 0;
                if (m_rasterizer_axis_tready && !m_rasterizer_axis_tlast && !apply && applied && !pixelInPipeline)
                begin
                    s_cmd_axis_tready <= 1;
                    state <= COMMAND_IN;
                end
            end
            COMMAND_IN:
            begin
                if (s_cmd_axis_tvalid)
                begin
                    // Command decoding
                    case (s_cmd_axis_tdata[OP_POS +: OP_SIZE])
                    OP_TRIANGLE_STREAM:
                    begin
                        /* verilator lint_off WIDTH */
                        streamCounter <= s_cmd_axis_tdata[DATABUS_SCALE_FACTOR_LOG2 +: OP_IMM_SIZE - DATABUS_SCALE_FACTOR_LOG2];
                        /* verilator lint_off WIDTH */
                        state <= EXEC_TRIANGLE_STREAM;
                    end
                    OP_TEXTURE_STREAM:
                    begin
                        confTextureMode <= s_cmd_axis_tdata[TEXTURE_STREAM_MODE_POS +: TEXTURE_STREAM_IMM_SIZE];
                        case (s_cmd_axis_tdata[TEXTURE_STREAM_SIZE_POS +: TEXTURE_STREAM_IMM_SIZE])
                            `OP_TEXTURE_STREAM_MODE_32x32: 
                                streamCounter <= (32 * 32 * 2) / DATABUS_SCALE_FACTOR;
                            `OP_TEXTURE_STREAM_MODE_64x64: 
                                streamCounter <= (64 * 64 * 2) / DATABUS_SCALE_FACTOR;
                            `OP_TEXTURE_STREAM_MODE_128x128:
                                streamCounter <= (128 * 128 * 2) / DATABUS_SCALE_FACTOR;
                            `OP_TEXTURE_STREAM_MODE_256x256:
                                streamCounter <= (256 * 256 * 2) / DATABUS_SCALE_FACTOR; 
                            default:
                            begin
                            end
                        endcase

                        if (|s_cmd_axis_tdata[TEXTURE_STREAM_SIZE_POS +: TEXTURE_STREAM_IMM_SIZE])
                        begin
                            if (TEXTURE_STREAM_WIDTH == 16)
                            begin
                                state <= EXEC_TEXTURE_STREAM_16;
                            end
                            else 
                            begin
                                state <= EXEC_TEXTURE_STREAM;
                            end
                        end
                        else
                        begin
                            s_cmd_axis_tready <= 0;
                            state <= WAIT_FOR_IDLE;    
                        end
                    end
                    OP_RENDER_CONFIG:
                    begin
                        /* verilator lint_off WIDTH */
                        streamCounter <= s_cmd_axis_tdata[3 : 0];
                        /* verilator lint_off WIDTH */
                        state <= EXEC_RENDER_CONFIG;
                    end
                    OP_FRAMEBUFFER:
                    begin
                        s_cmd_axis_tready <= 0;
                        colorBufferCmdCommit <= s_cmd_axis_tdata[OP_FRAMEBUFFER_COMMIT_POS];
                        colorBufferCmdMemset <= s_cmd_axis_tdata[OP_FRAMEBUFFER_MEMSET_POS];
                        depthBufferCmdCommit <= s_cmd_axis_tdata[OP_FRAMEBUFFER_COMMIT_POS];
                        depthBufferCmdMemset <= s_cmd_axis_tdata[OP_FRAMEBUFFER_MEMSET_POS];
                        colorBufferApply <= s_cmd_axis_tdata[OP_FRAMEBUFFER_COLOR_BUFFER_SELECT_POS];
                        depthBufferApply <= s_cmd_axis_tdata[OP_FRAMEBUFFER_DEPTH_BUFFER_SELECT_POS];
                        apply <= 1;
                        state <= WAIT_FOR_IDLE;
                    end
                    OP_NOP_STREAM:
                    begin
                        s_cmd_axis_tready <= 0;
                        state <= WAIT_FOR_IDLE;
                    end
                    endcase
                    parameterComplete <= 0;
                end
            end
            EXEC_TRIANGLE_STREAM:
            begin
                s_cmd_axis_tready <= m_rasterizer_axis_tready;
                if (m_rasterizer_axis_tready)
                begin
                    m_rasterizer_axis_tvalid <= s_cmd_axis_tvalid;
                    m_rasterizer_axis_tdata <= s_cmd_axis_tdata;
                    if (s_cmd_axis_tvalid)
                    begin
                        streamCounter <= streamCounter - 1;
                        if (streamCounter == 1)
                        begin
                            s_cmd_axis_tready <= 0;
                            m_rasterizer_axis_tlast <= 1;
                            state <= WAIT_FOR_IDLE;
                        end
                    end
                end
            end
            EXEC_TEXTURE_STREAM:
            begin
                s_cmd_axis_tready <= m_texture_axis_tready;
                if (m_texture_axis_tready)
                begin
                    m_texture_axis_tvalid <= s_cmd_axis_tvalid;
                    m_texture_axis_tdata <= s_cmd_axis_tdata[0 +: TEXTURE_STREAM_WIDTH];
                    if (s_cmd_axis_tvalid)
                    begin
                        streamCounter <= streamCounter - 1;
                        if (streamCounter == 1)
                        begin
                            s_cmd_axis_tready <= 0;
                            m_texture_axis_tlast <= 1;
                            state <= WAIT_FOR_IDLE;
                        end
                    end
                end
            end
            EXEC_TEXTURE_STREAM_16:
            begin : Copy16
                reg [15:0] lsp;

                if (m_texture_axis_tready)
                begin
                    if (wlsp == 0)
                    begin
                        m_texture_axis_tvalid <= s_cmd_axis_tvalid;
                        m_texture_axis_tdata <= s_cmd_axis_tdata[0 +: 16];
                        lsp <= s_cmd_axis_tdata[16 +: 16];
                        if (s_cmd_axis_tvalid)
                        begin
                            s_cmd_axis_tready <= 0;
                            wlsp <= 1;
                        end
                    end
                    else 
                    begin
                        m_texture_axis_tdata <= lsp;
                        s_cmd_axis_tready <= 1;
                        wlsp <= 0;

                        streamCounter <= streamCounter - 1;
                        if (streamCounter == 1)
                        begin
                            s_cmd_axis_tready <= 0;
                            m_texture_axis_tlast <= 1;
                            state <= WAIT_FOR_IDLE;
                        end
                    end
                end
            end
            EXEC_RENDER_CONFIG:
            begin
                if (s_cmd_axis_tvalid)
                begin
                    configReg[streamCounter[0 +: 3]] <= s_cmd_axis_tdata[0 +: 16];
                    s_cmd_axis_tready <= 0;
                    state <= WAIT_FOR_IDLE;
                end
            end
            default:
            begin
            end
            endcase

            case (fbControlState)
            FB_CONTROL_WAITFORCOMMAND:
            begin
                if (apply)
                begin
                    if (applied == 0)
                    begin
                        fbControlState <= FB_CONTROL_WAITFOREND;
                    end
                end
            end
            FB_CONTROL_WAITFOREND:
            begin
                apply <= 0;
                colorBufferApply <= 0;
                depthBufferApply <= 0;
                if (applied)
                begin
                    fbControlState <= FB_CONTROL_WAITFORCOMMAND;
                end
            end
            endcase
        end
    end

endmodule