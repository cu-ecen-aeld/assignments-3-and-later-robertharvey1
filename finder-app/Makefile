# Toolchain for native and cross compilation
CC_NATIVE = gcc
CC_CROSS = aarch64-none-linux-gnu-gcc

# Source Files and target
SOURCES = writer.c
TARGET_NATIVE = writer
TARGET_CROSS = writer_cross

# C Flags
C_FLAGS = -Wall

# Rules for Native Compilation

native: $(TARGET_NATIVE)

$(TARGET_NATIVE): $(SOURCES)
	$(CC_NATIVE) $(CFLAGS) -o $@ $(SOURCES)

# Rules for cross compilation
cross: $(TARGET_CROSS)

$(TARGET_CROSS): $(SOURCES)
	$(CC_CROSS) $(CFLAGS) -o $@ $(SOURCES)


# Clean
clean:
	rm -f $(TARGET_NATIVE) $(TARGET_CROSS)