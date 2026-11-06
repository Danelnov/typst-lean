import Lean
import TypstInfoview.Basic
import TypstInfoview.Options
import TypstInfoview.Compile
import TypstInfoview.Widget

/-!
# The `#typst` and `#toTypst` commands

Flow: elaborate the term → infer `ToTypst` → evaluate to `String` →
assemble the document → compile with Typst → attach the widget to the info tree.
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
  let opts ← getOptions
  let body ← liftTermElabM (evalToTypst t)
  let cfg : Typst.Config := {
    bin := opts.get typst.bin.name typst.bin.defValue
    preamble := opts.get typst.preamble.name typst.preamble.defValue
    mode := opts.get typst.mode.name typst.mode.defValue
  }
  let source := Typst.assemble cfg body
  let theme := opts.get typst.theme.name typst.theme.defValue
  let theme := if ["auto", "light", "dark"].contains theme then theme else "auto"
  let showSource := opts.get typst.showSource.name typst.showSource.defValue
  let result ← Typst.compileSvg cfg source
  let base : List (String × Json) :=
    [("theme", theme), ("source", source), ("showSource", showSource)]
  let props : Json := Json.mkObj <| base ++
    match result with
    | .ok svg    => [("svg", (svg : String))]
    | .error msg => [("error", (msg : String))]
  if let .error msg := result then
    logWarning m!"#typst: la compilación falló (detalles en el Infoview)\n{msg}"
  liftCoreM <| Widget.savePanelWidgetInfo (hash typstView.javascript) (pure props) stx
