/* benchmark_runner.c - High-Resolution Native C Timing Harness */

#include "athanor_simd.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

static double get_time_sec(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

int main(void) {
    const size_t N = 1000000;
    double* a = (double*)malloc(N * sizeof(double));
    double* b = (double*)malloc(N * sizeof(double));
    double* out = (double*)malloc(N * sizeof(double));

    for (size_t i = 0; i < N; ++i) {
        a[i] = (double)(i % 100) * 0.01;
        b[i] = (double)((i + 1) % 100) * 0.01;
    }

    /* Benchmark dot product */
    double t0 = get_time_sec();
    double dot = 0.0;
    const int ITERS = 100;
    for (int it = 0; it < ITERS; ++it) {
        dot += athanor_dot_product_f64(N, a, b);
    }
    double t1 = get_time_sec();
    double elapsed = (t1 - t0) / (double)ITERS;
    double gflops = (2.0 * (double)N * 1e-9) / elapsed;

    printf("[Athanor SIMD C Benchmark] Dot product (N=%zu): %.3f ms (%.2f GFLOPS, checksum=%.4f)\n",
           N, elapsed * 1000.0, gflops, dot);

    /* Benchmark vector add */
    t0 = get_time_sec();
    for (int it = 0; it < ITERS; ++it) {
        athanor_vector_add_f64(N, a, b, out);
    }
    t1 = get_time_sec();
    elapsed = (t1 - t0) / (double)ITERS;
    double gb_sec = (3.0 * (double)N * sizeof(double) * 1e-9) / elapsed;

    printf("[Athanor SIMD C Benchmark] Vector add (N=%zu): %.3f ms (%.2f GB/s throughput)\n",
           N, elapsed * 1000.0, gb_sec);

    free(a);
    free(b);
    free(out);
    return 0;
}
