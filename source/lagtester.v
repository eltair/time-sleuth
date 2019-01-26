module lagtester(
    input clock,

    input [2:0] RES_CONFIG,

    inout wire SDA,
    inout wire SCL,

    input SENSOR,
    output [7:0] DVI_RED,
    output [7:0] DVI_GREEN,
    output [7:0] DVI_BLUE,
    output DVI_DE,
    output DVI_HSYNC,
    output DVI_VSYNC,
    output DVI_CLOCK,

    output TFP410_reset,
    output LED
);
    wire internal_clock;
    wire pll_locked;
    wire tfp410_ready;
    reg [7:0] config_data;
    reg sensor_input; /* synthesis keep */
    wire [7:0] config_data_crossed;
    VideoMode videoMode;

    always @(posedge clock) begin
        config_data <= { 5'd0, RES_CONFIG };
        sensor_input <= SENSOR;
    end

    ///////////////////////////////////////////
    // clocks
    pll_main pll(
        .clock(clock),
        .reset(1'b0),
        .data(config_data),

        .clock_out(internal_clock),
        .clock_out_video(DVI_CLOCK),
        .locked(pll_locked)
    );

    ///////////////////////////////////////////
    // video
    data_cross #(
        .WIDTH(8)
    ) video_data_cross (
        .clkIn(clock),
        .clkOut(internal_clock),
        .dataIn(config_data),
        .dataOut(config_data_crossed)
    );

    video_config video_config(
        .clock(internal_clock),
        .data_in(config_data_crossed),
        .videoMode(videoMode)
    );

    video video(
        .clock(internal_clock),
        .videoMode(videoMode),
        .red(DVI_RED),
        .green(DVI_GREEN),
        .blue(DVI_BLUE),
        .de(DVI_DE),
        .hsync(DVI_HSYNC),
        .vsync(DVI_VSYNC)
    );
    ///////////////////////////////////////////

    ///////////////////////////////////////////
    // dvi transmitter
    TFP410 tfp410(
        .clk(clock),
        .reset(1'b1),
        .output_ready(pll_locked),
        .sda(SDA),
        .scl(SCL),
        .ready(tfp410_ready)
    );
    ///////////////////////////////////////////

    assign LED = tfp410_ready;
    assign TFP410_reset = 1'b1;

endmodule