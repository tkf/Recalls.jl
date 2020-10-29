# Recalls

## API summary

Recording calls:

* `@recall function f(...) ... end`
* `@recall f(...)`
* `recall()`: reply last record created by `@recall`. To debug last record,
  use `@run recall()`.
* `Recalls.CALLS`: a vector of record created by `@recall`.

Recording variables:

* `@note v₁ v₂ ... vₙ`: record variables.
* `Recalls.NOTES`: a vector of record created by `@note`.
