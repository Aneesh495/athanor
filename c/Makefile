CC ?= clang
CFLAGS ?= -O3 -fPIC -Wall -Wextra -Iinclude
LDLIBS := -lm
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    TARGET = libathanor_simd.dylib
    LDFLAGS := -shared -install_name @rpath/libathanor_simd.dylib
    RPATH_FLAGS := -Wl,-rpath,@loader_path
else
    TARGET = libathanor_simd.so
    LDFLAGS := -shared
    RPATH_FLAGS := -Wl,-rpath,'$$ORIGIN'
endif

all: $(TARGET) bench

$(TARGET): src/athanor_simd.o
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)

src/athanor_simd.o: src/athanor_simd.c include/athanor_simd.h
	$(CC) $(CFLAGS) -c $< -o $@

bench: src/benchmark_runner.c $(TARGET)
	$(CC) $(CFLAGS) $< -L. -lathanor_simd $(RPATH_FLAGS) $(LDLIBS) -o $@

clean:
	rm -f src/*.o $(TARGET) bench

.PHONY: all clean
