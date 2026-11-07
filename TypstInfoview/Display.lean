import Lean
import TypstInfoview.Options
import TypstInfoview.Compile
import TypstInfoview.Widget

/-!
# `Typst.display`: the API for other packages

`#typst` is a thin layer over this function. Any command, term elaborator or tactic
can call it to attach a compiled Typst document to the syntax node `stx`: the
Infoview shows it when the cursor is on a line that touches that node.

To visualize the *steps* of a process (e.g. a tactic block), call it once per
step, with the `stx` of that step.
-/

open Lean Elab Widget

namespace Typst

/-- Compiles `body` and attaches the result as a widget to `stx`.

* `adjust` modifies the configuration read from the `typst.*` options
  (for example `fun c => { c with mode := "markup" }`).
* `warn := false` suppresses the warning when Typst fails; the error is still
  shown inside the widget. Useful when called once per step.
-/
def display (stx : Syntax) (body : String)
    (adjust : Config → Config := id) (warn : Bool := true) : CoreM Unit := do
  let opts ← getOptions
  let cfg := adjust {
    bin := opts.get typst.bin.name typst.bin.defValue
    preamble := opts.get typst.preamble.name typst.preamble.defValue
    mode := opts.get typst.mode.name typst.mode.defValue
  }
  let source := assemble cfg body
  let theme := opts.get typst.theme.name typst.theme.defValue
  let theme := if ["auto", "light", "dark"].contains theme then theme else "auto"
  let showSource := opts.get typst.showSource.name typst.showSource.defValue
  let result ← compileSvg cfg source
  let base : List (String × Json) :=
    [("theme", theme), ("source", source), ("showSource", showSource)]
  let props : Json := Json.mkObj <| base ++
    match result with
    | .ok svg    => [("svg", (svg : String))]
    | .error msg => [("error", (msg : String))]
  if warn then
    if let .error msg := result then
      withRef stx <| logWarning m!"typst: compilation failed (details in the Infoview)\n{msg}"
  savePanelWidgetInfo (hash typstView.javascript) (pure props) stx

end Typst
