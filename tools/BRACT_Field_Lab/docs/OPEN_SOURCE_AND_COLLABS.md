# OPEN SOURCE + COLLABORATION PLAN

## The best story

Field Lab should be able to say:

> Originally built as an internal instrument while designing the BLUME identity. Released so other designers can subject their own letterforms to the same kind of controlled visual physics.

That is much stronger than launching an effect generator with no provenance.

---

# Collaboration model

A collaboration can exchange **behavior**, not only logos.

Example:

1. BLUME saves a field recipe.
2. Collaborator loads their lettermark.
3. The same field recipe behaves differently because their geometry is different.
4. Collaborator sends back one of their field recipes.
5. BLUME applies it to the canonical B.

The collaboration becomes:

```text
YOUR FORM × OUR FIELD
OUR FORM × YOUR FIELD
```

rather than two logos placed beside one another.

---

# Preset portability

Current JSON presets include font paths, which are local-machine-specific.

Before open-source release, split preset concepts:

## Document preset
Contains everything, including source reference and manual geometry.

## Field preset
Contains only:
- Field types.
- Parameters.
- Field order.
- Masks optionally normalized to geometry space.

A Field preset should be portable to someone else's glyph.

---

# Licensing choices to consider later

Do not pick a license accidentally.

## MIT
Very permissive. Easy adoption, including commercial forks.

## Apache-2.0
Also permissive, with explicit patent language.

## GPL-3.0
Copyleft. Derivative distributed software generally needs to remain under compatible open terms.

The correct choice depends on whether the goal is maximum creative adoption or keeping derivatives open. Consult a lawyer for business-critical licensing decisions.

Do **not** bundle commercial font files with the repository unless their license explicitly allows redistribution.

---

# Repository structure for public release

```text
field-lab/
├── README.md
├── LICENSE
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── CHANGELOG.md
├── examples/
├── docs/
├── processing-sketch/
└── engine/
```

Long term, separate the generic engine from a BLUME skin/example.
