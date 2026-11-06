import Lean

/-!
# Configuration options (`set_option typst.… `)
-/

register_option typst.theme : String := {
  defValue := "auto"
  descr := "Tema del Infoview para #typst: \"auto\" (detectar), \"light\" (letras negras) o \"dark\" (letras blancas)."
}

register_option typst.bin : String := {
  defValue := ""
  descr := "Ruta al ejecutable de Typst. Vacío: usa la variable de entorno TYPST_BIN y, si no existe, `typst` del PATH."
}

register_option typst.preamble : String := {
  defValue := ""
  descr := "Código Typst que se antepone al documento (imports, #set, definiciones...)."
}

register_option typst.mode : String := {
  defValue := "math"
  descr := "\"math\": el resultado de ToTypst se envuelve en `$ ... $`. \"markup\": se usa tal cual."
}

register_option typst.showSource : Bool := {
  defValue := true
  descr := "Mostrar (plegado) el código Typst generado debajo del resultado."
}
