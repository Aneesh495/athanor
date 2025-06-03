/* athanor_simd.h - High-Performance SIMD Vector Math and BLAS Kernel Definitions */

#ifndef ATHANOR_SIMD_H
#define ATHANOR_SIMD_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Vectorized linear algebra and BLAS primitives */
double athanor_dot_product_f64(size_t n, const double* restrict a, const double* restrict b);
void athanor_vector_add_f64(size_t n, const double* restrict a, const double* restrict b, double* restrict out);
void athanor_vector_mul_f64(size_t n, const double* restrict a, const double* restrict b, double* restrict out);
void athanor_vector_axpy_f64(size_t n, double alpha, const double* restrict x, double* restrict y);

/* Matrix multiplication: C = alpha * A * B + beta * C */
void athanor_gemm_f64(size_t m, size_t n, size_t k,
                      double alpha, const double* restrict a, size_t lda,
                      const double* restrict b, size_t ldb,
                      double beta, double* restrict c, size_t ldc);

/* Polynomial evaluation using SIMD Horner scheme */
void athanor_horner_eval_f64(size_t n, const double* restrict x,
                             size_t degree, const double* restrict coeffs,
                             double* restrict out);

/* Fast neural network activations */
void athanor_relu_f64(size_t n, const double* restrict x, double* restrict out);
void athanor_gelu_f64(size_t n, const double* restrict x, double* restrict out);
void athanor_sigmoid_f64(size_t n, const double* restrict x, double* restrict out);

#ifdef __cplusplus
}
#endif

#endif /* ATHANOR_SIMD_H */
