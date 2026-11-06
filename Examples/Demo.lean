import TypstInfoview

/-! Demo: open this file in VS Code and place the cursor on each `#typst`. -/

-- 1. Basic instances
#typst (42 : Nat)
#typst [1, 2, 3]
#typst ((1 : Nat), "hola")

-- 2. Your own type + instance
inductive Expr where
  | num : Nat → Expr
  | var : String → Expr
  | add : Expr → Expr → Expr
  | mul : Expr → Expr → Expr
  | div : Expr → Expr → Expr
  | pow : Expr → Expr → Expr

open Expr in
def Expr.toTypst : Expr → String
  | num n   => toString n
  | var x   => x
  | add a b => s!"({a.toTypst} + {b.toTypst})"
  | mul a b => s!"{a.toTypst} dot {b.toTypst}"
  | div a b => Typst.frac a.toTypst b.toTypst
  | pow a b => Typst.sup (a.toTypst) (b.toTypst)

instance : ToTypst Expr := ⟨Expr.toTypst⟩

open Expr in
#typst add (div (add (var "x") (num 1)) (pow (var "y") (num 2))) (num 1)

-- 3. Handwritten Typst in markup mode, with a custom preamble
set_option typst.mode "markup" in
set_option typst.preamble "#set text(fill: blue)" in
#typst (Typst.Raw.mk "= Título\nTexto con $integral_0^1 x^2 d x = 1/3$.")

-- 4. Force dark theme (manual fallback)
set_option typst.theme "dark" in
#toTypst (Typst.Raw.mk "sum_(k=0)^n k = (n(n+1))/2")
