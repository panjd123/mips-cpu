`ifndef COMMON_VH
`define COMMON_VH
`define code_path "./code.txt"
`define data_path "./data.txt"


typedef logic [31:0] Vec32;
typedef logic [5:0] Vec6;
typedef logic [4:0] Vec5;
typedef logic [1:0] Vec2;
typedef logic [2:0] Vec3;
typedef logic [32:0] Vec33;
typedef logic [25:0] Vec26;
typedef logic [15:0] Vec16;

typedef enum Vec6
{
    ADD = 6'b100000,
    ADDU = 6'b100001,
    SUB = 6'b100010,
    SUBU = 6'b100011,
    LSHIFT = 6'b000000,
    LRSHIFT = 6'b000010,
    ARSHIFT = 6'b000011,
    LSHIFTV = 6'b000100,
    LRSHIFTV = 6'b000110,
    ARSHIFTV = 6'b000111,
    AND = 6'b100100,
    OR = 6'b100101,
    XOR = 6'b100110,
    NOR = 6'b100111,
    SLT = 6'b101010,
    SLTU = 6'b101011
} AluOp;

typedef enum Vec32
{
    // 6 + 5 + 5 + 5 + 5 + 6 = 32
    nop     = 32'b000000_00000_00000_00000_00000_000000,

    // codet + rs + rt + rd + shamt + funct
    addu    = 32'b000000_?????_?????_?????_00000_100001,
    subu    = 32'b000000_?????_?????_?????_00000_100011,
    add     = 32'b000000_?????_?????_?????_00000_100000,
    sub     = 32'b000000_?????_?????_?????_00000_100010,
    sll     = 32'b000000_00000_?????_?????_?????_000000,
    srl     = 32'b000000_00000_?????_?????_?????_000010,
    sra     = 32'b000000_00000_?????_?????_?????_000011,
    sllv    = 32'b000000_?????_?????_?????_00000_000100,
    srlv    = 32'b000000_?????_?????_?????_00000_000110,
    srav    = 32'b000000_?????_?????_?????_00000_000111,
    And     = 32'b000000_?????_?????_?????_00000_100100,
    Or      = 32'b000000_?????_?????_?????_00000_100101,
    Xor     = 32'b000000_?????_?????_?????_00000_100110,
    Nor     = 32'b000000_?????_?????_?????_00000_100111,
    slt     = 32'b000000_?????_?????_?????_00000_101010,
    sltu    = 32'b000000_?????_?????_?????_00000_101011,
    jr      = 32'b000000_?????_00000_00000_?????_001000,
    jalr    = 32'b000000_?????_00000_?????_?????_001001, 
    syscall = 32'b000000_00000_00000_00000_00000_001100,
    mult    = 32'b000000_?????_?????_00000_00000_011000,
    multu   = 32'b000000_?????_?????_00000_00000_011001,
    div     = 32'b000000_?????_?????_00000_00000_011010,
    divu    = 32'b000000_?????_?????_00000_00000_011011,
    mfhi    = 32'b000000_00000_00000_?????_00000_010000,
    mflo    = 32'b000000_00000_00000_?????_00000_010010,
    mthi    = 32'b000000_?????_00000_00000_00000_010001,
    mtlo    = 32'b000000_?????_00000_00000_00000_010011,

    // codet + rs + rt + 16'imm
    addi    = 32'b001000_?????_?????_????????????????,
    addiu   = 32'b001001_?????_?????_????????????????,
    andi    = 32'b001100_?????_?????_????????????????,
    ori     = 32'b001101_?????_?????_????????????????,
    xori    = 32'b001110_?????_?????_????????????????,
    slti    = 32'b001010_?????_?????_????????????????,
    sltiu   = 32'b001011_?????_?????_????????????????,
    lw      = 32'b100011_?????_?????_????????????????,
    lb      = 32'b100000_?????_?????_????????????????,
    lbu     = 32'b100100_?????_?????_????????????????,
    lh      = 32'b100001_?????_?????_????????????????,
    lhu     = 32'b100101_?????_?????_????????????????,
    sw      = 32'b101011_?????_?????_????????????????,
    sb      = 32'b101000_?????_?????_????????????????,
    sh      = 32'b101001_?????_?????_????????????????,
    beq     = 32'b000100_?????_?????_????????????????,
    bne     = 32'b000101_?????_?????_????????????????,
    blez    = 32'b000110_?????_00000_????????????????,
    bgtz    = 32'b000111_?????_00000_????????????????,
    bgez    = 32'b000001_?????_00001_????????????????,
    bltz    = 32'b000001_?????_00000_????????????????,
    lui     = 32'b001111_00000_?????_????????????????,

    // codet + 26'imm
    jal     = 32'b000011_??????????????????????????,
    j       = 32'b000010_??????????????????????????
} InstructionCode;

typedef struct packed {
    InstructionCode instructionCode;
    Vec5 rs, rt, rd;
    Vec16 imm16;
    Vec26 imm26;
    Vec6 funct;
    Vec5 shamt;
} Instruction;

typedef enum Vec2 {
    gprWriteRegisterSrc_rt,
    gprWriteRegisterSrc_rd,
    gprWriteRegisterSrc_ra
} GprWriteRegisterSrc;

typedef enum Vec2{
    gprWriteInputSrc_aluResult,
    gprWriteInputSrc_dmResult,
    gprWriteInputSrc_imm16
} GprWriteInputSrc;

typedef enum logic{
    aluInput1Src_gpr1,
    aluInput1Src_pc
} AluInput1Src;

typedef enum Vec2{
    aluInput2Src_gpr2,
    aluInput2Src_ext,
    aluInput2Src_4
}AluInput2Src;

typedef enum Vec2{
    pcJumpModeSrc_next=2'b00,
    pcJumpModeSrc_beq=2'b01,
    pcJumpModeSrc_abs=2'b10,
    pcJumpModeSrc_absreg=2'b11
}PcJumpModeSrc;

typedef enum Vec2{
    pcJumpInputSrc_0,
    pcJumpInputSrc_ext,
    pcJumpInputSrc_imm26,
    pcJumpInputSrc_gpr
}PcJumpInputSrc;

typedef struct packed{
    GprWriteRegisterSrc gprWriteRegisterSrc;
    GprWriteInputSrc gprWriteInputSrc;
    logic gprWriteEnabled;
    AluInput1Src aluInput1Src;
    AluInput2Src aluInput2Src;
    AluOp aluOp;
    logic dmWriteEnabled;
    logic extSign;
    PcJumpModeSrc pcJumpModeSrc;
    PcJumpInputSrc pcJumpInputSrc;
}ControlSignal;
`endif