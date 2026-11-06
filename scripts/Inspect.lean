import Lean
open Lean Elab

/-- Processes a Lean file and dumps the User Widgets remaining in the info tree. -/
partial def walk (t : InfoTree) : IO Unit := do
  match t with
  | .context _ t => walk t
  | .node i cs =>
    if let .ofUserWidgetInfo w := i then
      let (props, _) := (w.props.run {} : Id _)
      let field (k : String) : String :=
        match props.getObjVal? k with
        | .ok (.str s) => s!"<{s.length} chars: {(s.take 60).replace "\n" "⏎"}…>"
        | .ok j => j.compress
        | .error _ => "-"
      IO.println s!"WIDGET hash={w.javascriptHash} theme={field "theme"} svg={field "svg"} error={field "error"}"
    cs.forM walk
  | .hole _ => pure ()

unsafe def main (args : List String) : IO UInt32 := do
  enableInitializersExecution
  initSearchPath (← findSysroot)
  let path := args.head!
  let input ← IO.FS.readFile path
  let inputCtx := Parser.mkInputContext input path
  let (header, parserState, messages) ← Parser.parseHeader inputCtx
  let (env, messages) ← processHeader header {} messages inputCtx
  let env := env.setMainModule `Demo
  let cmdState := { Command.mkState env messages {} with infoState.enabled := true }
  let s ← IO.processCommands inputCtx parserState cmdState
  for msg in s.commandState.messages.toList do
    IO.print (← msg.toString)
  for t in s.commandState.infoState.trees do walk t
  return 0
