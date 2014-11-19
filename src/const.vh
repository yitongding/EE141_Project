`ifndef CONST
`define CONST

`define MEM_DATA_BITS 128
`define MEM_TAG_BITS 5
`define MEM_ADDR_BITS 28
`define MEM_DATA_CYCLES 4

`define CPU_ADDR_BITS 32
`define CPU_INST_BITS 32
`define CPU_DATA_BITS 32
`define CPU_OP_BITS 4
`define CPU_WMASK_BITS 16
`define CPU_TAG_BITS 15

// Cache constants
`define IDX_ADDR_OFFSET 4:2
`define IDX_ADDR_INDEX 12:5
`define IDX_ADDR_TAG 31:13
`define IDX_ADDR_DRAM 27:5

`define IDX_TAG_TAG 18:0
`define IDX_TAG_VALID 19
`define IDX_TAG_DIRTY 20

`define SZ_OFFSET 3
`define SZ_INDEX 8
`define SZ_TAG (32-`SZ_OFFSET-`SZ_INDEX-2)
`define SZ_METADATA 2
`define SZ_TAGLINE `SZ_TAG+`SZ_METADATA
`define SZ_CACHELINE 256 

`define CAP_CACHE 256
`define SZ_CACHE $clog2(`CAP_CACHE)

// PC address on reset
`define PC_RESET 32'h00001FFC

// The NOP instruction
`define INSTR_NOP {12'd0, 5'd0, `FNC_ADD_SUB, 5'd0, `OPC_ARI_ITYPE}

`define CSR_TOHOST 12'h51E
`define CSR_HARTID 12'h50B
`define CSR_STATUS 12'h50A

`endif //CONST
