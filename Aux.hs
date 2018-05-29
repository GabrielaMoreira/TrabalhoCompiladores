module Aux where

import Parser
import Head
import RBTree

busca = searchFast compVar
insere = insert compVar
compVar ((a :>: _),_) ((b :>: _),_) = compare a b

insereTabelaSimbolos :: [Declaracao] -> TabelaDeSimbolos -> Integer -> TabelaDeSimbolos
insereTabelaSimbolos [] ts p = ts
insereTabelaSimbolos ((Decl t []):ds) ts p = insereTabelaSimbolos ds ts p
insereTabelaSimbolos ((Decl t (i:is)):ds) ts p = if (busca ts ((i :>: t), p) /= Nothing)
                                                     then error ("Variavel " ++ show i ++ " duplamente declarada")
                                                     else insereTabelaSimbolos ((Decl t is):ds) (insere ts ((i :>: t),p)) (p+1)


tipoEA _ (Numero (Inteiro _)) = TInt
tipoEA _ (Numero (Flutuante _)) = TFloat
tipoEA ts (Var i) = case busca ts ((i :>: TInt), 0) of
                         Nothing -> error("Variavel " ++ show i ++ " indefinida")
                         Just ((_ :>: t),_) -> t

posicao i ts = case busca ts ((i :>: TInt), 0) of
                    Nothing -> error("Variavel " ++ show i ++ " indefinida")
                    Just ((_ :>: _),p) -> show p

toConst (Inteiro 0) = "iconst_0"
toConst (Inteiro 1) = "iconst_1"
toConst (Inteiro 2) = "iconst_2"
toConst (Inteiro 3) = "iconst_3"
toConst (Inteiro 4) = "iconst_4"
toConst (Inteiro 5) = "iconst_5"
toConst (Inteiro n) = if (n >= -128 && n <= 127)
                         then "bipush " ++ show n
                         else "ldc " ++ show n
toConst (Flutuante n) = if (n >= -128 && n <= 127)
                           then "bipush " ++ show n
                           else "ldc " ++ show n

encontraCoercoes :: TabelaDeSimbolos -> ExpressaoAritmetica -> ([[Char]], Tipo)
encontraCoercoes ts (Multiplicacao a b) = let (sa,sb,t) = coercaoExpr ts (encontraCoercoes ts a) (encontraCoercoes ts b) in (sa ++ sb ++ ["imul"], t)
encontraCoercoes ts (Divisao a b) =       let (sa,sb,t) = coercaoExpr ts (encontraCoercoes ts a) (encontraCoercoes ts b) in (sa ++ sb ++ ["idiv"], t)
encontraCoercoes ts (Adicao a b) =        let (sa,sb,t) = coercaoExpr ts (encontraCoercoes ts a) (encontraCoercoes ts b) in (sa ++ sb ++ ["iadd"], t)
encontraCoercoes ts (Subtracao a b) =     let (sa,sb,t) = coercaoExpr ts (encontraCoercoes ts a) (encontraCoercoes ts b) in (sa ++ sb ++ ["isub"], t)
encontraCoercoes ts (Neg a) =             let (sa,t) = encontraCoercoes ts a in (sa ++  ["/-/"],t)
encontraCoercoes ts (Numero a) =          ([toConst a], tipoEA ts (Numero a))
encontraCoercoes ts (Var i) =             (["iload " ++ posicao i ts], tipoEA ts (Var i))

coercaoExpr ts (a,TInt) (b,TInt) = (a,b,TInt)
coercaoExpr ts (a,TFloat) (b,TFloat) = (a,b,TFloat)
coercaoExpr ts (a,TInt) (b,TFloat) = (a ++ ["i2F"],b,TFloat)
coercaoExpr ts (a,TFloat) (b,TInt) = (a,b ++ ["i2F"],TFloat)

showLista [c] = c
showLista (c:cs) = c ++ "\n" ++ showLista cs
