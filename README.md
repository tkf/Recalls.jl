# Recalls

## API summary

Recording calls:

* `@recall function f(...) ... end`
* `@recall f(...)`
* `recall()`: replay last record created by `@recall`. To debug last record,
  use `@run recall()`.
* `Recalls.CALLS`: a vector of records created by `@recall`.

Recording variables:

* `@note v₁ v₂ ... vₙ`: record variables.
* `Recalls.NOTES`: a vector of records created by `@note`.
