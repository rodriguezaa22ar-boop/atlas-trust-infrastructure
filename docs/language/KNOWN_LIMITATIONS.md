# Atlas Language Known Limitations

## AL-001 Boundary

AL-001 is a documentation and candidate-contract milestone. It does not
implement or demonstrate:

- a Rust workspace or compiler;
- a lexer, parser, name resolver, type checker, or diagnostics engine;
- an `atlas lang` command;
- an execution runtime or task state machine;
- live or synthetic executable adapters;
- Rego as runtime policy authority;
- agent or model execution;
- approval enforcement, expiry, revocation, or separation of duties;
- portable canonicalization;
- an authoritative `plan_hash`;
- cross-platform deterministic compiler output;
- runtime binding hashes;
- atomic runtime writes, locking, cancellation, or retries;
- receipt generation or language-plan replay;
- a package/module system;
- a language server;
- parallel workflows or distributed execution.

## Candidate Contracts

The execution-plan schema is a candidate structural contract. Schema validity
means only that a JSON document has the expected AL-001 shape. It does not mean
that a compiler produced the document, referenced capabilities exist, policy
allows the plan, approval exists, an adapter is registered, or execution is
safe or available.

The example uses proposed `agent.model.invoke`, `artifact.read`, and
`artifact.write` capability references. AL-001 does not add those capabilities
to the authoritative manifest. A future checker or preflight must deny them
until a separate approved milestone registers them.

## Hashing and Determinism

AL-001 does not specify canonical plan bytes. The example therefore omits
`plan_hash`, contract digests, compiler artifact digests, and a source digest.
Their structural fields may be reserved by the candidate schema, but no value
is authoritative until the applicable canonicalization and identity contracts
are frozen and backed by golden vectors.

## Runtime and Proof

No private input, model output, endpoint, credential, or host configuration is
included. No claim is made about model correctness, external authorization,
legal sufficiency, compliance, complete event coverage, production readiness,
immutable storage, or tamper-proof infrastructure.
