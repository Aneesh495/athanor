# Abstract Interpretation and Formal Safety Verification

Abstract interpretation is a formal theory of sound semantic approximation, pioneered by Patrick and Radhia Cousot. It enables static analyzers and optimizing compilers to compute provable bounds on program execution without running all possible concrete inputs or relying on incomplete test cases.

Athanor incorporates abstract interpretation as a core verification engine to prove program safety contracts prior to native code emission.

## 1. Mathematical Foundations: Galois Connections

Let $(\mathcal{P}(\mathbb{R}), \subseteq)$ be the concrete semantic domain (sets of real numbers) and $(A, \sqsubseteq)$ be the abstract domain. An abstract interpretation is formalized by a Galois Connection $(\alpha, \gamma)$:
$$\mathcal{P}(\mathbb{R}) \underset{\alpha}{\overset{\gamma}{\rightleftarrows}} A$$
satisfying:
$$\forall S \subseteq \mathbb{R}, \quad \forall a \in A: \quad \alpha(S) \sqsubseteq a \iff S \subseteq \gamma(a)$$

where:
- $\alpha(S)$ is the **abstraction function** mapping a concrete set of values to its best abstract over-approximation.
- $\gamma(a)$ is the **concretization function** giving the set of all real numbers represented by abstract element $a$.
- Soundness guarantees that for every concrete operation $f$ and corresponding abstract operator $f^\sharp$:
  $$\forall x \in \gamma(a), \quad f(x) \in \gamma(f^\sharp(a))$$

## 2. Abstract Domains in Athanor

### 2.1 The Interval Domain ($\mathcal{I}$)
An interval $[l, u]$ represents the continuous set $\{x \in \mathbb{R} \mid l \le x \le u\}$, where $l \in \mathbb{R} \cup \{-\infty\}$ and $u \in \mathbb{R} \cup \{+\infty\}$.

Elementary interval arithmetic operations:
- **Addition**:
  $$[l_1, u_1] +^\sharp [l_2, u_2] = [l_1 + l_2, u_1 + u_2]$$
- **Subtraction**:
  $$[l_1, u_1] -^\sharp [l_2, u_2] = [l_1 - u_2, u_1 - l_2]$$
- **Multiplication**:
  $$[l_1, u_1] \times^\sharp [l_2, u_2] = [\min(P), \max(P)], \quad P = \{l_1 l_2, l_1 u_2, u_1 l_2, u_1 u_2\}$$
- **Division**:
  $$[l_1, u_1] /^\sharp [l_2, u_2] = [l_1, u_1] \times^\sharp [1/u_2, 1/l_2] \quad \text{provided } 0 \notin [l_2, u_2]$$
- **Lattice Join (Union Over-approximation)**:
  $$[l_1, u_1] \sqcup [l_2, u_2] = [\min(l_1, l_2), \max(u_1, u_2)]$$
- **Lattice Meet (Intersection)**:
  $$[l_1, u_1] \sqcap [l_2, u_2] = [\max(l_1, l_2), \min(u_1, u_2)] \quad (\text{or } \bot \text{ if empty})$$

### 2.2 The Sign Domain ($\mathcal{S}$)
A discrete five-element lattice:
$$\mathcal{S} = \{ \bot, -, 0, +, \top \}$$
where $\bot$ indicates dead/unreachable code and $\top$ indicates an unknown sign. The sign domain allows immediate constant-time branch pruning when signs are known.

### 2.3 Affine Arithmetic Forms
To mitigate the dependency problem (where interval arithmetic over-estimates error because it forgets variable correlations, such as in $x - x$), Athanor provides affine forms:
$$\hat{x} = x_0 + \sum_{i=1}^k x_i \epsilon_i, \quad \epsilon_i \in [-1, 1]$$
Affine forms track shared noise symbols $\epsilon_i$, yielding exact zero cancellations when subtracting correlated variables.

## 3. Formal Safety Verifier

Athanor exposes automated static verification routines through `src/abstract/verifier.lisp`:

### 3.1 Division-by-Zero Freedom
`verify-division-by-zero-free(expr, env)`:
- Recursively walks the expression tree.
- For each division node $(/ \, u \, v)$, evaluates the abstract interval of denominator $v$ under the input environment $env$.
- Proves $0 \notin \llbracket v \rrbracket^\sharp$. If zero is contained within the denominator bounds, the offending subexpression is flagged with counterexample bounds.

### 3.2 Target Range Containment Proofs
`verify-interval-bounds(expr, env, target)`:
- Computes the sound output interval $\llbracket expr \rrbracket^\sharp$.
- Asserts that the computed interval is strictly enclosed within `target`:
  $$\text{lo}(\llbracket expr \rrbracket^\sharp) \ge \text{lo}(target) \quad \land \quad \text{hi}(\llbracket expr \rrbracket^\sharp) \le \text{hi}(target)$$
- Useful for validating normalized activations, probabilities in $[0.0, 1.0]$, and trigonometric bounds.

### 3.3 Integer Register Overflow Freedom
`verify-overflow-free-integer(expr, env, bit-width)`:
- Computes interval bounds for discrete signed arithmetic.
- Proves that intermediate and final accumulator values reside within the two's-complement hardware bounds:
  $$[-2^{W-1}, 2^{W-1} - 1]$$
- Guarantees that DSP and arithmetic pipelines cannot suffer undefined integer overflow when compiled to native assembly.
