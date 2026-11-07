import Lean
open Lean Elab

/-!
Prueba headless: procesa un archivo Lean y lista los User Widgets que quedan en el árbol
de info, con la línea donde se mostrarán (el Infoview los muestra por línea del cursor).

  lake env lean --run scripts/Inspect.lean Archivo.lean [--source]
-/

partial def walk (fm : FileMap) (showSrc : Bool) (t : InfoTree) : IO Unit := do
  match t with
  | .context _ t => walk fm showSrc t
  | .node i cs =>
    if let .ofUserWidgetInfo w := i then
      let (props, _) := (w.props.run {} : Id _)
      let field (k : String) : String :=
        match props.getObjVal? k with
        | .ok (.str s) => s!"<{s.length} chars: {(s.take 40).replace "\n" "⏎"}…>"
        | .ok j => j.compress
        | .error _ => "-"
      let line := match w.stx.getPos? with
        | some p => toString (fm.toPosition p).line
        | none => "?"
      IO.println s!"WIDGET line={line} theme={field "theme"} svg={field "svg"} error={field "error"}"
      if showSrc then
        if let .ok (.str s) := props.getObjVal? "source" then
          IO.println ("---- source ----\n" ++ s ++ "----------------")
    cs.forM (walk fm showSrc)
  | .hole _ => pure ()

unsafe def main (args : List String) : IO UInt32 := do
  enableInitializersExecution
  initSearchPath (← findSysroot)
  let path := args.head!
  let showSrc := args.contains "--source"
  let input ← IO.FS.readFile path
  let inputCtx := Parser.mkInputContext input path
  let (header, parserState, messages) ← Parser.parseHeader inputCtx
  let (env, messages) ← processHeader header {} messages inputCtx
  let env := env.setMainModule `Demo
  let cmdState := { Command.mkState env messages {} with infoState.enabled := true }
  let s ← IO.processCommands inputCtx parserState cmdState
  for msg in s.commandState.messages.toList do
    IO.print (← msg.toString)
  for t in s.commandState.infoState.trees do walk inputCtx.fileMap showSrc t
  return 0
