# Version number, which should match the official version of the tool we are building
RISCV_GDB_VERSION := 10.1.0

# Customization ID, which should identify the customization added to the original by SiFive
FREEDOM_GDB_METAL_ID := dev-$(shell cd src/riscv-gdb/ && git log --pretty=format:'%h' -1)

# Characteristic tags, which should be usable for matching up providers and consumers
FREEDOM_GDB_METAL_RISCV_TAGS = rv32i rv64i m a f d c v b zfh
FREEDOM_GDB_METAL_TOOLS_TAGS = gdb-metal
