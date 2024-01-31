{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ViewPatterns #-}

module Operational where

import Kumar
import Semantic
import Logic.Proof
import Data.Maybe (fromJust)

data EvalJ = EvalJ Env Expr Value
  deriving Eq

instance Show EvalJ where
  show (EvalJ r e v) = show r ++ " |- " ++ show e ++ " => " ++ show v


infer :: Env -> Expr -> EvalJ
infer rho e | v <- eval rho e = EvalJ rho e v

mkProof :: Expr -> Proof EvalJ
mkProof = fromJust . prove . infer []

ex = parseExpr "fun x -> 1"
ex' = infer [] ex

instance Explain EvalJ where
  premises (EvalJ r (EInt n) v) = [[]]
  premises (EvalJ r (ECon n) v) = [[]]
  premises (EvalJ r (EVar x) v) = [[]]

  {- Fun -}
  premises (EvalJ r (EFun x e) (VClosure x' e' r')) = [[]]

  {- App -}
  premises (EvalJ r (EApp e1 e2) v)
    | (VClosure x e3 r) <- eval r e1
    , v2 <- eval r e2
      = [[EvalJ r e1 (VClosure x e3 r), EvalJ r e2 v2, EvalJ ((x,v2):r) e3 v]]
  
  {- AppCon -}
  premises (EvalJ r (EApp e1 e2) v)
    | (VCon n vs) <- eval r e1
    , v2 <- eval r e2
      = [[EvalJ r e1 (VCon n vs), EvalJ r e2 v2]]

  {- Let -}
  premises (EvalJ r (ELet (DSimp x e1) e2) v)
    | v1 <- eval r e1
      = [[EvalJ r e1 v1, EvalJ ((x,v1):r) e2 v]]

  {- Case -}
  premises (EvalJ r (ECase e alts) v)
    | v <- eval r e
    , Just (r',e') <- firstMatch v alts
      = [[EvalJ r e v, EvalJ (r'++r) e' v]]

  {- Desugar -}

  {- Let -}
  -- premises (EvalJ env e v) = [[EvalJ env e v]]