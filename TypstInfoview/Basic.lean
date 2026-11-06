/-!
# `ToTypst`: the conversion backend

`ToTypst α` describes how to write a term of type `α` as Typst code.

Convention: instances produce a Typst *math-mode expression*
(the content that goes between `$ ... $`). The `#typst` command wraps it.
This makes it possible to compose instances without worrying about their
surroundings: the `List α` instance simply joins the outputs for `α`.
-/

universe u

/-- Types whose terms can be written as Typst code (math mode). -/
class ToTypst (α : Type u) where
  toTypst : α → String

export ToTypst (toTypst)

namespace Typst

/-- Handwritten Typst code, emitted as-is (without escaping). -/
structure Raw where
  src : String
  deriving Repr, Inhabited, BEq

instance : ToTypst Raw := ⟨Raw.src⟩

/-- Escapes a Lean string for use as a Typst string literal. -/
def escapeString (s : String) : String :=
  s.foldl (init := "") fun acc c =>
    match c with
    | '"'  => acc ++ "\\\""
    | '\\' => acc ++ "\\\\"
    | c    => acc.push c

/-! ### Small combinators for writing instances -/

/-- `f(a, b, ...)` -/
def call (f : String) (args : List String) : String :=
  f ++ "(" ++ ", ".intercalate args ++ ")"

def frac (a b : String) : String := call "frac" [a, b]
def sqrt (a : String) : String := call "sqrt" [a]
def sup (a b : String) : String := s!"{a}^({b})"
def sub (a b : String) : String := s!"{a}_({b})"
def paren (a : String) : String := s!"({a})"

/-- A Typst matrix: `mat(a, b; c, d)`. -/
def mat (rows : List (List String)) : String :=
  "mat(" ++ "; ".intercalate (rows.map (", ".intercalate ·)) ++ ")"

end Typst

/-! ### Basic instances -/

instance : ToTypst Nat    := ⟨fun n => toString n⟩
instance : ToTypst Int    := ⟨fun n => toString n⟩
instance : ToTypst (Fin n) := ⟨fun i => toString i.val⟩
instance : ToTypst Bool   := ⟨fun b => if b then "top" else "bot"⟩
instance : ToTypst Unit   := ⟨fun _ => "()"⟩
instance : ToTypst String := ⟨fun s => "\"" ++ Typst.escapeString s ++ "\""⟩

instance {α : Type u} {β : Type u} [ToTypst α] [ToTypst β] : ToTypst (α × β) :=
  ⟨fun (a, b) => Typst.paren (toTypst a ++ ", " ++ toTypst b)⟩

instance {α : Type u} [ToTypst α] : ToTypst (List α) :=
  ⟨fun xs => ", ".intercalate (xs.map toTypst)⟩

instance {α : Type u} [ToTypst α] : ToTypst (Array α) :=
  ⟨fun xs => toTypst xs.toList⟩
