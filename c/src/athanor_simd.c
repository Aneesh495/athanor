/* athanor_simd.c - High-Performance SIMD Vector Math and BLAS Kernel Implementation */

#include "athanor_simd.h"
#include <math.h>

#if defined(__ARM_NEON)
#include <arm_neon.h>
#endif

double athanor_dot_product_f64(size_t n, const double* restrict a, const double* restrict b) {
    size_t i = 0;
    double sum = 0.0;

#if defined(__ARM_NEON)
    float64x2_t vsum0 = vdupq_n_f64(0.0);
    float64x2_t vsum1 = vdupq_n_f64(0.0);

    for (; i + 4 <= n; i += 4) {
        float64x2_t va0 = vld1q_f64(a + i);
        float64x2_t vb0 = vld1q_f64(b + i);
        float64x2_t va1 = vld1q_f64(a + i + 2);
        float64x2_t vb1 = vld1q_f64(b + i + 2);

        vsum0 = vfmaq_f64(vsum0, va0, vb0);
        vsum1 = vfmaq_f64(vsum1, va1, vb1);
    }

    float64x2_t vsum = vaddq_f64(vsum0, vsum1);
    sum = vgetq_lane_f64(vsum, 0) + vgetq_lane_f64(vsum, 1);
#endif

    for (; i < n; ++i) {
        sum += a[i] * b[i];
    }
    return sum;
}

void athanor_vector_add_f64(size_t n, const double* restrict a, const double* restrict b, double* restrict out) {
    size_t i = 0;

#if defined(__ARM_NEON)
    for (; i + 4 <= n; i += 4) {
        float64x2_t va0 = vld1q_f64(a + i);
        float64x2_t vb0 = vld1q_f64(b + i);
        float64x2_t va1 = vld1q_f64(a + i + 2);
        float64x2_t vb1 = vld1q_f64(b + i + 2);

        vst1q_f64(out + i, vaddq_f64(va0, vb0));
        vst1q_f64(out + i + 2, vaddq_f64(va1, vb1));
    }
#endif

    for (; i < n; ++i) {
        out[i] = a[i] + b[i];
    }
}

void athanor_vector_mul_f64(size_t n, const double* restrict a, const double* restrict b, double* restrict out) {
    size_t i = 0;

#if defined(__ARM_NEON)
    for (; i + 4 <= n; i += 4) {
        float64x2_t va0 = vld1q_f64(a + i);
        float64x2_t vb0 = vld1q_f64(b + i);
        float64x2_t va1 = vld1q_f64(a + i + 2);
        float64x2_t vb1 = vld1q_f64(b + i + 2);

        vst1q_f64(out + i, vmulq_f64(va0, vb0));
        vst1q_f64(out + i + 2, vmulq_f64(va1, vb1));
    }
#endif

    for (; i < n; ++i) {
        out[i] = a[i] * b[i];
    }
}

void athanor_vector_axpy_f64(size_t n, double alpha, const double* restrict x, double* restrict y) {
    size_t i = 0;

#if defined(__ARM_NEON)
    float64x2_t valpha = vdupq_n_f64(alpha);
    for (; i + 2 <= n; i += 2) {
        float64x2_t vx = vld1q_f64(x + i);
        float64x2_t vy = vld1q_f64(y + i);
        vst1q_f64(y + i, vfmaq_f64(vy, valpha, vx));
    }
#endif

    for (; i < n; ++i) {
        y[i] += alpha * x[i];
    }
}

void athanor_gemm_f64(size_t m, size_t n, size_t k,
                      double alpha, const double* restrict a, size_t lda,
                      const double* restrict b, size_t ldb,
                      double beta, double* restrict c, size_t ldc) {
    /* Scale existing C by beta */
    for (size_t i = 0; i < m; ++i) {
        for (size_t j = 0; j < n; ++j) {
            c[i * ldc + j] = (beta == 0.0) ? 0.0 : c[i * ldc + j] * beta;
        }
    }

    /* Cache-blocked tiled matrix multiplication with outer product update */
    const size_t block_k = 64;
    for (size_t p = 0; p < k; p += block_k) {
        size_t p_end = (p + block_k < k) ? p + block_k : k;
        for (size_t i = 0; i < m; ++i) {
            for (size_t l = p; l < p_end; ++l) {
                double a_val = alpha * a[i * lda + l];
                for (size_t j = 0; j < n; ++j) {
                    c[i * ldc + j] += a_val * b[l * ldb + j];
                }
            }
        }
    }
}

void athanor_horner_eval_f64(size_t n, const double* restrict x,
                             size_t degree, const double* restrict coeffs,
                             double* restrict out) {
    for (size_t i = 0; i < n; ++i) {
        double xi = x[i];
        double p = coeffs[degree];
        for (size_t d = degree; d > 0; --d) {
            p = p * xi + coeffs[d - 1];
        }
        out[i] = p;
    }
}

void athanor_relu_f64(size_t n, const double* restrict x, double* restrict out) {
    for (size_t i = 0; i < n; ++i) {
        double v = x[i];
        out[i] = (v > 0.0) ? v : 0.0;
    }
}

void athanor_gelu_f64(size_t n, const double* restrict x, double* restrict out) {
    const double sqrt_2_over_pi = 0.7978845608028654;
    const double coeff = 0.044715;
    for (size_t i = 0; i < n; ++i) {
        double v = x[i];
        double inner = sqrt_2_over_pi * (v + coeff * v * v * v);
        out[i] = 0.5 * v * (1.0 + tanh(inner));
    }
}

void athanor_sigmoid_f64(size_t n, const double* restrict x, double* restrict out) {
    for (size_t i = 0; i < n; ++i) {
        out[i] = 1.0 / (1.0 + exp(-x[i]));
    }
}
