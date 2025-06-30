# Relational Logic Programming: miniKanren, CLP(FD), and Datalog

Relational programming generalizes functional programming. While a function computes an output from fixed inputs ($y = f(x)$), a relation specifies a declarative constraint between values ($R(x, y)$). This enables bidirectional execution: running a relation forward computes outputs, running it backward synthesizes inputs, and running it with variables on both sides discovers all satisfying solutions.

Athanor implements three interrelated relational paradigms:
1. Pure first-order logic programming via miniKanren.
2. Finite domain constraint solving (CLP(FD)).
3. Deductive inference via stratified Datalog.

## 1. Pure Relational Logic (miniKanren)

Athanor embeds a micro-miniKanren core with standard extensions.

### Core Primitives
- **Logic Variables**: Unique variables allocated with `make-var`.
- **Substitution ($S$)**: Association list mapping unbound or bound logic variables to terms.
- **Walking (`walk`)**: Chains through substitutions to resolve canonical values.
- **Unification (`unify`)**: Robinson first-order unification with sound occurs check preventing circular definitions.
- **Goal**: A function mapping a substitution to a lazy stream of extended substitutions:
  $$\text{Goal}: S \to \text{Stream}(S)$$

### Stream Monads and Interleaving Search
To prevent depth-first infinite loops in recursive relations, miniKanren uses fair interleaving streams:
- `unit(s)`: Constructs a singleton stream.
- `mzero()`: Represents the empty stream (failure).
- `mplus(s1, s2)`: Interleaves two streams fairly, alternating evaluations so that infinite branches cannot starve parallel alternative branches.
- `bind(stream, goal)`: Monadic bind passing each substitution in `stream` to `goal`.

### Query Interface
- `== (u, v)`: Unification goal asserting equivalence between terms $u$ and $v$.
- `fresh ((vars...) goals...)`: Introduces lexically scoped logic variables.
- `conde ((clause1...) (clause2...))`: Relational disjunction (logical OR).
- `run n (q) goals...`: Reifies and returns up to $n$ satisfying values for query variable $q$.

## 2. Constraint Logic Programming Over Finite Domains (CLP(FD))

CLP(FD) enhances relational search over integer variables by pruning impossible values before exploring branches (consistency techniques):

$$\text{CSP} = \langle \mathcal{X}, \mathcal{D}, \mathcal{C} \rangle$$
where:
- $\mathcal{X} = \{x_1, \dots, x_n\}$ is a set of integer variables.
- $\mathcal{D} = \{D_1, \dots, D_n\}$ are finite domains ($D_i = [\min_i, \max_i] \subset \mathbb{Z}$).
- $\mathcal{C}$ is a set of constraints.

### Constraint Primitives in Athanor
- `in-range(var, lo, hi)`: Enforces interval bounds $[lo, hi]$ on $var$.
- `distinct-vars(vars)`: Enforces the global `all-different` constraint over a list of variables, preventing duplicate assignments.
- `sum-constraint(vars, target)`: Enforces linear equality $\sum_{i} x_i = target$.
- `clpfd-solve(vars, constraints)`: Solves the constraint problem using AC-3 domain reduction coupled with depth-first backtracking search.

## 3. Stratified Datalog Engine

Datalog is a declarative query language based on Horn clauses without function symbols, guaranteeing termination.

### Horn Clause Structure
$$\text{Head} \leftarrow \text{Body}_1, \text{Body}_2, \dots, \text{Body}_k$$
- Facts: Ground relations asserted into the database, such as `edge(1, 2)`.
- Rules: Deductive inferences, such as transitive closure:
  $$\text{path}(x, y) \leftarrow \text{edge}(x, y)$$
  $$\text{path}(x, z) \leftarrow \text{path}(x, y), \text{edge}(y, z)$$

### Semi-Naive Fixpoint Evaluation
Naive evaluation re-computes all previously derived facts in every iteration, leading to redundant work. Athanor uses semi-naive evaluation:
1. In round $i$, only rules that utilize at least one newly derived fact from round $i-1$ ($\Delta$-facts) are evaluated.
2. The iteration terminates when $\Delta$-facts is empty, reaching the unique minimal model (the least fixpoint).
3. Stratified negation-as-failure (`not`) is supported, ensuring well-founded semantics.
