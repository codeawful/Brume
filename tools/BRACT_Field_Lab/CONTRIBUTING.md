# CONTRIBUTING (PRE-RELEASE DRAFT)

This repository copy is currently an internal design-tool build, but the code is intentionally organized for later public contribution.

Principles for contributions:

1. New geometry effects should extend `GeometryField` rather than add special-case logic to the render loop.
2. Effects must be deterministic when animation is disabled.
3. New state that changes output must serialize into presets.
4. Raster effects must not silently mutate source geometry.
5. Do not add bundled fonts/artwork without explicit redistribution rights.
6. Prefer understandable math and comments over “clever” opaque code.
7. Add an ELI5 note for non-obvious algorithms.

Before a public repository launch, add automated tests and choose an explicit software license.
