# Atlas Language Specification 0.1

## Status and Normative Language

This is the AL-001 candidate source specification for `atlas/0.1`. It documents
intended static behavior; no parser or compiler is implemented by AL-001.

The terms **MUST**, **MUST NOT**, **SHOULD**, and **MAY** are normative. Formal
syntax is owned by [GRAMMAR_V0_1.ebnf](GRAMMAR_V0_1.ebnf).

## Source File

An Atlas source file:

- MUST be UTF-8;
- MUST begin with `language "atlas/0.1"`;
- MUST use the `.atlas` extension;
- MUST contain one or more declarations;
- MUST NOT use shell expansion, command substitution, executable expressions,
  or implicit environment interpolation.

Whitespace is not semantic. Unknown properties and duplicate properties are
errors. Names are case-sensitive.

## Keywords

The reserved declaration and control keywords are `language`, `agent`, `task`,
`workflow`, `limits`, and `run`. The reserved literal/call keywords are
`artifact`, `true`, and `false`. `policy` and `required` are contextual reserved
values for approval and receipt properties. Reserved words MUST NOT be used as
declaration names.

## Declarations

### `agent`

An `agent` names a requester. It MUST declare:

- `provider`: a logical provider reference;
- `requests`: a non-empty, duplicate-free list of capability references;
- `policy`: an external policy reference.

An agent requests capabilities but cannot define, approve, or grant them.
Provider configuration and secrets do not appear in source.

### `task`

A `task` is a bounded unit of intended work. Version 0.1 tasks MUST declare:

- `agent`: a previously declared agent;
- `input` and `output`: workspace-relative artifact references;
- `goal`: human-authored task intent;
- `approval = policy`;
- `receipt = required`;
- `limits` containing `timeout`, `attempts`, and `max_tokens`.

The goal is source content. A public metadata-only plan MUST reference it or
bind it through a source digest; it MUST NOT embed the raw goal text.

### `workflow`

A `workflow` contains ordered `run` statements naming declared tasks. Version
0.1 has exactly one entry point named `main`. Tasks run sequentially in source
order. Parallelism and dynamic task creation are not part of version 0.1.

## Values

Version 0.1 supports strings, multiline strings, integers, booleans, durations,
lists, declaration references, and `artifact("path")` calls. There are no
implicit casts and no `null` value.

Durations use an integer followed by `ms`, `s`, `m`, or `h`. Implementations
MUST reject zero or unbounded limits and MUST define supported upper bounds.

## Artifact Paths

Artifact paths MUST be workspace-relative and begin with `./`. Implementations
MUST reject absolute paths, `..` traversal, symlink escape, NUL bytes, and paths
outside the configured workspace. Source paths are logical references, not
machine-specific resolved paths.

## Static Semantics

A conforming checker MUST reject:

- an unsupported language version;
- duplicate declarations, properties, capabilities, or workflow entry points;
- missing required properties;
- unknown properties or declaration kinds;
- unresolved agent or task references;
- invalid types or unbounded limits;
- unsafe artifact paths;
- a task without a required receipt;
- source that defines capabilities, approvals, policies, adapters, executable
  paths, or shell commands;
- capability, policy, provider, or adapter references not recognized by the
  relevant external contract.

The last category fails closed. The AL-001 example uses proposed language
capability references that are not registered by this milestone, so future
governance preflight must reject them until an approved capability milestone
adds them.

## Plan Identity Boundary

A future deterministic plan identity includes the language and compiler
versions, source digest, workflow structure, declarations, logical provider and
adapter identity, declared model reference when present, requested
capabilities, policy reference, checked-in contract/configuration digests,
limits, artifact-reference structure, and receipt requirements.

It excludes secret values, credentials, raw goals or prompts, raw model output,
environment-resolved endpoints, machine-specific paths, temporary directories,
runtime timestamps, process identifiers, and network-assigned addresses.
Actual non-secret runtime bindings belong in later run events and receipts.

AL-001 and AL-002 do not define canonical plan bytes and therefore MUST NOT
claim an authoritative portable `plan_hash`.
