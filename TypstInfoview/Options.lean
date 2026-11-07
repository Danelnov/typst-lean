import Lean

/-!
# Configuration options (`set_option typst.… `)
-/

register_option typst.theme : String := {
  defValue := "auto"
  descr := "Infoview theme for #typst: \"auto\" (detect), \"light\" (black text) or \"dark\" (white text)."
}

register_option typst.bin : String := {
  defValue := ""
  descr := "Path to the Typst executable. Empty: use the TYPST_BIN environment variable and, if absent, `typst` from PATH."
}

register_option typst.preamble : String := {
  defValue := ""
  descr := "Typst code prepended to the document (imports, #set, definitions...)."
}

register_option typst.mode : String := {
  defValue := "math"
  descr := "\"math\": the result of ToTypst is wrapped in `$ ... $`. \"markup\": used as-is."
}

register_option typst.showSource : Bool := {
  defValue := true
  descr := "Show (folded) the generated Typst code below the result."
}
