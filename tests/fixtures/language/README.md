# Atlas Language Safety Fixtures

The valid structural fixture remains
`examples/language/hello.plan.json`. Each JSON file under `invalid/` describes
one unsafe mutation of that valid plan using a JSON `path` and replacement
`value`. `bin/dev-language-safety` applies each mutation independently and
requires the resulting plan to fail `atlas.execution_plan.v1` validation.

This single-mutation form keeps the negative reason explicit and avoids copies
of the complete plan drifting away from the positive fixture. These files are
test data only; they are not executable plans, approvals, capabilities, or
runtime inputs.
