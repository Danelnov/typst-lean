import Lean
import TypstInfoview.Basic
import TypstInfoview.Options
import TypstInfoview.Compile
import TypstInfoview.Widget
import TypstInfoview.Display

/-!
# The `#typst` and `#toTypst` commands

Flow: elaborate the term → infer `ToTypst` → evaluate to `String` →
`Typst.display` (assemble the document, compile, attach the widget).
-/

open Lean Elab Command Term Widget

/-- Elaborates and evaluates `ToTypst.toTypst t : String`. Lean's elaborator
infers the instance by unification, just as it does for any other typeclass call. -/
unsafe def evalToTypstUnsafe (t : Term) : TermElabM String := do
  Term.evalTerm String (mkConst ``String) (← `(ToTypst.toTypst $t))

@[implemented_by evalToTypstUnsafe]
opaque evalToTypst (t : Term) : TermElabM String

/-- `#typst t` renders `t` (any type with a `ToTypst` instance) in the Infoview. -/
syntax (name := typstCmd) "#typst " term : command

/-- An alias for `#typst`. -/
syntax (name := toTypstCmd) "#toTypst " term : command

macro_rules
  | `(#toTypst $t) => `(#typst $t)

@[command_elab typstCmd]
def elabTypstCmd : CommandElab := fun stx => do
  let `(#typst $t) := stx | throwUnsupportedSyntax
  let body ← liftTermElabM (evalToTypst t)
  liftCoreM <| Typst.display stx body
