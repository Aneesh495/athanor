CC ?= clang
CFLAGS ?= -O3 -fPIC -Wall -Wextra -Iinclude
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    TARGET = libathanor_simd.dylib
    LDFLAGS := -shared -lm -install_name @rpath/libathanor_simd.dylib
    RPATH_FLAGS := -Wl,-rpath,@loader_path
else
    TARGET = libathanor_simd.so
    LDFLAGS := -shared -lm
    RPATH_FLAGS := -Wl,-rpath,'$$ORIGIN'
endif

all: $(TARGET) bench

$(TARGET): src/athanor_simd.o
	$(CC) $(LDFLAGS) -o $@ $^

src/athanor_simd.o: src/athanor_simd.c include/athanor_simd.h
	$(CC) $(CFLAGS) -c $< -o $@

bench: src/benchmark_runner.c $(TARGET)
	$(CC) $(CFLAGS) $< -L. -lathanor_simd $(RPATH_FLAGS) -o $@

clean:
	rm -f src/*.o $(TARGET) bench

.PHONY: all clean
