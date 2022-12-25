module CompNoCom
import Data.Vect

data TyExp
    = Tint
    | Tbool

Val : TyExp -> Type
Val Tint = Int
Val Tbool = Bool

data HasTypeVar : (i : Fin n) -> Vect n TyExp -> TyExp -> Type where
    StopVar : HasTypeVar FZ (tVar :: vcntxt) tVar 
    PopVar  : HasTypeVar kFin vcntxt tVar 
           -> HasTypeVar (FS kFin) (uVar :: vcntxt) tVar

data Exp : (vEnv: Vect n TyExp) -> (fEnv: (TyExp, TyExp)) -> TyExp -> Type where
  ExpVar : HasTypeVar iFin vEnv t -> Exp vEnv fEnv t
  ExpVal : (x : Int) -> Exp vEnv fEnv Tint
  ExpAddition : Exp vEnv fEnv Tint -> Exp vEnv fEnv Tint -> Exp vEnv fEnv Tint
  ExpSubtraction : Exp vEnv fEnv Tint -> Exp vEnv fEnv Tint -> Exp vEnv fEnv Tint
  ExpMultiplication : Exp vEnv fEnv Tint -> Exp vEnv fEnv Tint -> Exp vEnv fEnv Tint
  ExpIfThenElse : Exp vEnv fEnv Tbool -> Exp vEnv fEnv t -> Exp vEnv fEnv t -> Exp vEnv fEnv t
  ExpOr : Exp vEnv fEnv Tbool -> Exp vEnv fEnv Tbool -> Exp vEnv fEnv Tbool
  ExpAnd : Exp vEnv fEnv Tbool -> Exp vEnv fEnv Tbool -> Exp vEnv fEnv Tbool
  ExpNot : Exp vEnv fEnv Tbool -> Exp vEnv fEnv Tbool
  ExpEqual : Exp vEnv fEnv Tint -> Exp vEnv fEnv Tint -> Exp vEnv fEnv Tbool
  ExpNotEqual : Exp vEnv fEnv Tint -> Exp vEnv fEnv Tint -> Exp vEnv fEnv Tbool
  ExpLessThan : Exp vEnv fEnv Tint -> Exp vEnv fEnv Tint -> Exp vEnv fEnv Tbool
  ExpLessThanEqual : Exp vEnv fEnv Tint -> Exp vEnv fEnv Tint -> Exp vEnv fEnv Tbool
  ExpGreaterThan : Exp vEnv fEnv Tint -> Exp vEnv fEnv Tint -> Exp vEnv fEnv Tbool
  ExpGreaterThanEqual : Exp vEnv fEnv Tint -> Exp vEnv fEnv Tint -> Exp vEnv fEnv Tbool
  ExpFuncCall: Exp vEnv (s,t) s -> Exp vEnv (s,t) t
--start med at skrive med simple programmer, og udvikle det mere
-- når man har variabler er dependent types mest relevant

record FunDecl where
  constructor MkFunDecl
  fd_var_type: TyExp
  fd_return_type: TyExp
  body: Exp [fd_var_type] (fd_var_type, fd_return_type) fd_return_type

record OpenProgram where
  constructor MkOpenProgram
  op_funDecl : FunDecl
  op_return_type: TyExp
  op_arg_type : TyExp
  val_arg : Val op_arg_type
  op_mainExp : Exp [op_arg_type] (op_funDecl.fd_var_type, op_funDecl.fd_return_type) op_return_type

record Program where
  constructor MkProgram
  p_funDecl: FunDecl
  p_return_type: TyExp
  p_mainExp: Exp [] (p_funDecl.fd_var_type, p_funDecl.fd_return_type) p_return_type

data VarEnv : Vect n TyExp -> Type where
    Nil  : VarEnv Nil
    (::) : Val a 
            -> VarEnv ecntxt 
            -> VarEnv (a :: ecntxt)

lookupVar : HasTypeVar i lcontex t -> VarEnv lcontex -> Val t
lookupVar StopVar (x :: xs) = x
lookupVar (PopVar k) (x :: xs) = lookupVar k xs

evalOpenProg : (op: OpenProgram) -> Val op.op_return_type
evalOpenProg (MkOpenProgram op_funDecl op_return_type op_arg_type val_arg (ExpVar x)) = lookupVar x (val_arg :: Nil)
evalOpenProg (MkOpenProgram op_funDecl Tint op_arg_type val_arg (ExpVal x)) = x
evalOpenProg (MkOpenProgram op_funDecl Tint op_arg_type val_arg (ExpAddition x y)) = evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg x) + evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg y)
evalOpenProg (MkOpenProgram op_funDecl Tint op_arg_type val_arg (ExpSubtraction x y)) = evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg x) - evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg y)
evalOpenProg (MkOpenProgram op_funDecl Tint op_arg_type val_arg (ExpMultiplication x y)) = evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg x) * evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg y)
evalOpenProg (MkOpenProgram op_funDecl op_return_type op_arg_type val_arg (ExpIfThenElse x y z)) = if evalOpenProg ( MkOpenProgram op_funDecl Tbool op_arg_type val_arg x) then evalOpenProg ( MkOpenProgram op_funDecl op_return_type op_arg_type val_arg y) else evalOpenProg (assert_smaller z $ MkOpenProgram op_funDecl op_return_type op_arg_type val_arg z)
evalOpenProg (MkOpenProgram op_funDecl Tbool op_arg_type val_arg (ExpOr x y)) = evalOpenProg ( MkOpenProgram op_funDecl Tbool op_arg_type val_arg x) || evalOpenProg ( MkOpenProgram op_funDecl Tbool op_arg_type val_arg y)
evalOpenProg (MkOpenProgram op_funDecl Tbool op_arg_type val_arg (ExpAnd x y)) = evalOpenProg ( MkOpenProgram op_funDecl Tbool op_arg_type val_arg x) && evalOpenProg ( MkOpenProgram op_funDecl Tbool op_arg_type val_arg y)
evalOpenProg (MkOpenProgram op_funDecl Tbool op_arg_type val_arg (ExpNot x)) = not $ evalOpenProg ( MkOpenProgram op_funDecl Tbool op_arg_type val_arg x)
evalOpenProg (MkOpenProgram op_funDecl Tbool op_arg_type val_arg (ExpEqual x y)) = evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg x) == evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg y)
evalOpenProg (MkOpenProgram op_funDecl Tbool op_arg_type val_arg (ExpNotEqual x y)) = evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg x) /= evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg y)
evalOpenProg (MkOpenProgram op_funDecl Tbool op_arg_type val_arg (ExpLessThan x y)) = evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg x) < evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg y)
evalOpenProg (MkOpenProgram op_funDecl Tbool op_arg_type val_arg (ExpLessThanEqual x y)) = evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg x) <= evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg y)
evalOpenProg (MkOpenProgram op_funDecl Tbool op_arg_type val_arg (ExpGreaterThan x y)) = evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg x) > evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg y)
evalOpenProg (MkOpenProgram op_funDecl Tbool op_arg_type val_arg (ExpGreaterThanEqual x y)) = evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg x) >= evalOpenProg ( MkOpenProgram op_funDecl Tint op_arg_type val_arg y)
evalOpenProg (MkOpenProgram op_funDecl (op_funDecl.fd_return_type) op_arg_type val_arg (ExpFuncCall x)) 
                = evalOpenProg (
                    MkOpenProgram op_funDecl (op_funDecl.fd_return_type) op_funDecl.fd_var_type (
                      evalOpenProg (
                        MkOpenProgram op_funDecl (op_funDecl.fd_var_type) op_arg_type val_arg x
                      ) 
                    ) op_funDecl.body
                ) 
              
evalProg : (p: Program) -> Val p.p_return_type
evalProg (MkProgram _ _ (ExpVar StopVar)) impossible
evalProg (MkProgram _ _ (ExpVar (PopVar x))) impossible
evalProg (MkProgram p_funDecl Tint (ExpVal x)) = x
evalProg (MkProgram p_funDecl Tint (ExpAddition x y)) = evalProg ( MkProgram p_funDecl Tint x) + evalProg ( MkProgram p_funDecl Tint y)
evalProg (MkProgram p_funDecl Tint (ExpSubtraction x y)) = evalProg ( MkProgram p_funDecl Tint x) - evalProg ( MkProgram p_funDecl Tint y)
evalProg (MkProgram p_funDecl Tint (ExpMultiplication x y)) = evalProg ( MkProgram p_funDecl Tint x) * evalProg ( MkProgram p_funDecl Tint y)
evalProg (MkProgram p_funDecl p_return_type (ExpIfThenElse x y z)) = if evalProg ( MkProgram p_funDecl Tbool x) then evalProg ( MkProgram p_funDecl p_return_type y) else evalProg (assert_smaller z $ MkProgram p_funDecl p_return_type z)
evalProg (MkProgram p_funDecl Tbool (ExpOr x y)) = evalProg ( MkProgram p_funDecl Tbool x) || evalProg ( MkProgram p_funDecl Tbool y)
evalProg (MkProgram p_funDecl Tbool (ExpAnd x y)) = evalProg ( MkProgram p_funDecl Tbool x) && evalProg ( MkProgram p_funDecl Tbool y)
evalProg (MkProgram p_funDecl Tbool (ExpNot x)) = not $ evalProg ( MkProgram p_funDecl Tbool x)
evalProg (MkProgram p_funDecl Tbool (ExpEqual x y)) = evalProg ( MkProgram p_funDecl Tint x) == evalProg ( MkProgram p_funDecl Tint y)
evalProg (MkProgram p_funDecl Tbool (ExpNotEqual x y)) = evalProg ( MkProgram p_funDecl Tint x) /= evalProg ( MkProgram p_funDecl Tint y)
evalProg (MkProgram p_funDecl Tbool (ExpLessThan x y)) = evalProg ( MkProgram p_funDecl Tint x) < evalProg ( MkProgram p_funDecl Tint y)
evalProg (MkProgram p_funDecl Tbool (ExpLessThanEqual x y)) = evalProg ( MkProgram p_funDecl Tint x) <= evalProg ( MkProgram p_funDecl Tint y)
evalProg (MkProgram p_funDecl Tbool (ExpGreaterThan x y)) = evalProg ( MkProgram p_funDecl Tint x) > evalProg ( MkProgram p_funDecl Tint y)
evalProg (MkProgram p_funDecl Tbool (ExpGreaterThanEqual x y)) = evalProg ( MkProgram p_funDecl Tint x) >= evalProg ( MkProgram p_funDecl Tint y)
evalProg (MkProgram p_funDecl (p_funDecl.fd_return_type) (ExpFuncCall x)) 
                = evalOpenProg (
                    MkOpenProgram p_funDecl (p_funDecl.fd_return_type) p_funDecl.fd_var_type (
                      evalProg (
                        MkProgram p_funDecl (p_funDecl.fd_var_type) x
                        )
                    ) p_funDecl.body 
                  )

---------------------Function declarations---------------------

--variable function declaration int
Variable1 : FunDecl
Variable1 = MkFunDecl Tint Tint (ExpVar (StopVar))

--variable function declaration bool
Variable2 : FunDecl
Variable2 = MkFunDecl Tbool Tbool (ExpVar (StopVar))

--variable function declaration 50
Variable50 : FunDecl
Variable50 = MkFunDecl Tint Tint (ExpVal 50)

--value function declaration 100
Value100 : FunDecl
Value100 = MkFunDecl Tint Tint (ExpVal 100)

--value function declaration 100 copy
Value100' : FunDecl
Value100' = MkFunDecl Tint Tint (ExpVal 100)

--value function declaration 200
Value200 : FunDecl
Value200 = MkFunDecl Tint Tint (ExpVal 200)

--addition function declaration variable
Addition1 : FunDecl
Addition1 = MkFunDecl Tint Tint (ExpAddition (ExpVar (StopVar)) (ExpVal 100)) 

--addition function declaration value
Addition2 : FunDecl
Addition2 = MkFunDecl Tint Tint (ExpAddition (ExpVal 20) (ExpVal 100))

--subtraction function declaration variable
Subtraction1 : FunDecl
Subtraction1 = MkFunDecl Tint Tint (ExpSubtraction (ExpVar (StopVar)) (ExpVal 100))

--subtraction function declaration value
Subtraction2 : FunDecl
Subtraction2 = MkFunDecl Tint Tint (ExpSubtraction (ExpVal 20) (ExpVal 100))

--subtraction function declaration variable
Multiplication1 : FunDecl
Multiplication1 = MkFunDecl Tint Tint (ExpMultiplication (ExpVar (StopVar)) (ExpVal 100))

--subtraction function declaration value
Multiplication2 : FunDecl
Multiplication2 = MkFunDecl Tint Tint (ExpMultiplication (ExpVal 20) (ExpVal 100))

--if then else with Less Than function declaration
IfThenElseLT : FunDecl
IfThenElseLT = MkFunDecl Tint Tint (ExpIfThenElse (ExpLessThan (ExpVar (StopVar)) (ExpVal 100)) (ExpVal 100) (ExpVal 200))

--if then else with Less Than Equal function declaration
IfThenElseLTE : FunDecl
IfThenElseLTE = MkFunDecl Tint Tint (ExpIfThenElse (ExpLessThanEqual (ExpVar (StopVar)) (ExpVal 100)) (ExpVal 100) (ExpVal 200))

--if then else with Greater Than function declaration
IfThenElseGT : FunDecl
IfThenElseGT = MkFunDecl Tint Tint (ExpIfThenElse (ExpGreaterThan (ExpVar (StopVar)) (ExpVal 100)) (ExpVal 100) (ExpVal 200))

--if then else with Greater Than Equal function declaration
IfThenElseGTE : FunDecl
IfThenElseGTE = MkFunDecl Tint Tint (ExpIfThenElse (ExpGreaterThanEqual (ExpVar (StopVar)) (ExpVal 100)) (ExpVal 100) (ExpVal 200))

--if then else with Equal function declaration
IfThenElseEQ : FunDecl
IfThenElseEQ = MkFunDecl Tint Tint (ExpIfThenElse (ExpEqual (ExpVar (StopVar)) (ExpVal 100)) (ExpVal 100) (ExpVal 200))

--if then else with Not Equal function declaration
IfThenElseNEQ : FunDecl
IfThenElseNEQ = MkFunDecl Tint Tint (ExpIfThenElse (ExpNotEqual (ExpVar (StopVar)) (ExpVal 100)) (ExpVal 100) (ExpVal 200))

--if then else with And function declaration
IfThenElseAND : FunDecl
IfThenElseAND = MkFunDecl Tint Tint (ExpIfThenElse (ExpAnd (ExpLessThan (ExpVar (StopVar)) (ExpVal 100)) (ExpGreaterThan (ExpVar (StopVar)) (ExpVal 200))) (ExpVal 100) (ExpVal 200))

--if then else with Or function declaration
IfThenElseOR : FunDecl
IfThenElseOR = MkFunDecl Tint Tint (ExpIfThenElse (ExpOr (ExpLessThan (ExpVar (StopVar)) (ExpVal 100)) (ExpGreaterThan (ExpVar (StopVar)) (ExpVal 200))) (ExpVal 100) (ExpVal 200))

--if then else with Not function declaration
IfThenElseNOTLT : FunDecl
IfThenElseNOTLT = MkFunDecl Tint Tint (ExpIfThenElse (ExpNot (ExpLessThan (ExpVar (StopVar)) (ExpVal 100))) (ExpVal 100) (ExpVal 200)) 

-- Define a function that returns True if the input is greater than 10, and False otherwise
isGreaterThanTen : FunDecl
isGreaterThanTen = MkFunDecl Tint Tbool (ExpGreaterThan (ExpVar (StopVar)) (ExpVal 10))

-- Define a function that returns the square of an integer if the input is greater than 100, and the input itself otherwise
squareOrInput : FunDecl
squareOrInput = MkFunDecl Tint Tint (ExpIfThenElse (ExpGreaterThan (ExpVar (StopVar)) (ExpVal 100)) (ExpMultiplication (ExpVar (StopVar)) (ExpVar (StopVar))) (ExpVar (StopVar)))

--Or function delcaration function declaration
Or1 : FunDecl
Or1 = MkFunDecl Tbool Tbool (ExpOr (ExpVar (StopVar)) (ExpEqual (ExpVal 100) (ExpVal 100))) 

--And function delcaration function declaration
And1 : FunDecl
And1 = MkFunDecl Tbool Tbool (ExpAnd (ExpVar (StopVar)) (ExpEqual (ExpVal 100) (ExpVal 100))) 

--Not function delcaration function declaration
Not1 : FunDecl
Not1 = MkFunDecl Tbool Tbool (ExpNot (ExpVar (StopVar))) 

--Equal function declaration function declaration
Equal1 : FunDecl
Equal1 = MkFunDecl Tint Tbool (ExpEqual (ExpVar (StopVar)) (ExpVal 100))

--Not Equal function declaration function declaration
NotEqual1 : FunDecl
NotEqual1 = MkFunDecl Tint Tbool (ExpNotEqual (ExpVar (StopVar)) (ExpVal 100))

--Less Than function declaration function declaration
LessThan1 : FunDecl
LessThan1 = MkFunDecl Tint Tbool (ExpLessThan (ExpVar (StopVar)) (ExpVal 100))

--Less Than Equal function declaration function declaration
LessThanEqual1 : FunDecl
LessThanEqual1 = MkFunDecl Tint Tbool (ExpLessThanEqual (ExpVar (StopVar)) (ExpVal 100))

--Greater Than function declaration function declaration
GreaterThan1 : FunDecl
GreaterThan1 = MkFunDecl Tint Tbool (ExpGreaterThan (ExpVar (StopVar)) (ExpVal 100))

--Greater Than Equal function declaration function declaration
GreaterThanEqual1 : FunDecl
GreaterThanEqual1 = MkFunDecl Tint Tbool (ExpGreaterThanEqual (ExpVar (StopVar)) (ExpVal 100))

--Function call that returns the nth fibonacci number
fib : FunDecl
fib = MkFunDecl Tint Tint (ExpIfThenElse (ExpLessThan (ExpVar (StopVar)) (ExpVal 2))
                                         (ExpVar (StopVar))
                                         (ExpAddition (ExpFuncCall (ExpSubtraction (ExpVar (StopVar)) (ExpVal 1)))
                                                      (ExpFuncCall (ExpSubtraction (ExpVar (StopVar)) (ExpVal 2)))))

--Function call that returns the factorial of an integer
fact : FunDecl
fact = MkFunDecl Tint Tint (ExpIfThenElse (ExpLessThanEqual (ExpVar (StopVar)) (ExpVal 1))
                                          (ExpVal 1)
                                          (ExpMultiplication (ExpVar (StopVar)) (ExpFuncCall (ExpSubtraction (ExpVar (StopVar)) (ExpVal 1)))))

--Function call that checks if a number is even. if the number is negative then make it positive and continue to check
isEven : FunDecl
isEven = MkFunDecl Tint Tbool (ExpIfThenElse (ExpLessThan (ExpVar (StopVar)) (ExpVal 0)) 
                                              (ExpFuncCall (ExpMultiplication (ExpVar (StopVar)) (ExpVal (-1))))
                                              (ExpIfThenElse (ExpLessThan (ExpVar (StopVar)) (ExpVal 2)) 
                                                             (ExpEqual (ExpVar (StopVar)) (ExpVal 0))
                                                             (ExpFuncCall (ExpSubtraction (ExpVar (StopVar)) (ExpVal 2)))))

--Function call that checks if a number is odd. if the number is negative then make it positive and continue to check
isOdd : FunDecl
isOdd = MkFunDecl Tint Tbool (ExpIfThenElse (ExpLessThan (ExpVar (StopVar)) (ExpVal 0)) 
                                             (ExpFuncCall (ExpMultiplication (ExpVar (StopVar)) (ExpVal (-1))))
                                             (ExpIfThenElse (ExpLessThan (ExpVar (StopVar)) (ExpVal 2)) 
                                                            (ExpNotEqual (ExpVar (StopVar)) (ExpVal 0))
                                                            (ExpFuncCall (ExpSubtraction (ExpVar (StopVar)) (ExpVal 2)))))

---------------------Programs---------------------

-- Create a Program that includes the add function and the necessary return type
prog1_add1 : Program
prog1_add1 = MkProgram Addition1 Tint (ExpFuncCall (ExpVal 3)) --103

prog2_add1 : Program
prog2_add1 = MkProgram Addition1 Tint (ExpFuncCall (ExpVal 0)) --100

-- Create a Program that includes the sub function and the necessary return type
prog1_sub1 : Program
prog1_sub1 = MkProgram Subtraction1 Tint (ExpFuncCall (ExpVal 3)) -- -97

prog2_sub1 : Program
prog2_sub1 = MkProgram Subtraction1 Tint (ExpFuncCall (ExpVal 0)) -- -100

-- Create a Program that includes the mul function and the necessary return type
prog1_mul1 : Program
prog1_mul1 = MkProgram Multiplication1 Tint (ExpFuncCall (ExpVal 3)) --300

prog2_mul1 : Program
prog2_mul1 = MkProgram Multiplication1 Tint (ExpFuncCall (ExpVal 0)) --0

-- Create a Program that includes the if then else function (less than) and the necessary return type
prog1_IfThenElseLT : Program
prog1_IfThenElseLT = MkProgram IfThenElseLT Tint (ExpFuncCall (ExpVal 300)) --200

prog2_IfThenElseLT : Program
prog2_IfThenElseLT = MkProgram IfThenElseLT Tint (ExpFuncCall (ExpVal 0)) --100

-- Create a Program that includes the if then else function (less than equal) and the necessary return type
prog1_IfThenElseLTE : Program
prog1_IfThenElseLTE = MkProgram IfThenElseLTE Tint (ExpFuncCall (ExpVal 300)) --200

prog2_IfThenElseLTE : Program
prog2_IfThenElseLTE = MkProgram IfThenElseLTE Tint (ExpFuncCall (ExpVal 0)) --100

-- Create a Program that includes the if then else function (greater than) and the necessary return type
prog1_IfThenElseGT : Program
prog1_IfThenElseGT = MkProgram IfThenElseGT Tint (ExpFuncCall (ExpVal 300)) --100

prog2_IfThenElseGT : Program
prog2_IfThenElseGT = MkProgram IfThenElseGT Tint (ExpFuncCall (ExpVal 0)) --200

-- Create a Program that includes the if then else function (greater than equal) and the necessary return type
prog1_IfThenElseGTE : Program
prog1_IfThenElseGTE = MkProgram IfThenElseGTE Tint (ExpFuncCall (ExpVal 300)) --100

prog2_IfThenElseGTE : Program
prog2_IfThenElseGTE = MkProgram IfThenElseGTE Tint (ExpFuncCall (ExpVal 0)) --200

-- Create a Program that includes the if then else function (equal) and the necessary return type
prog1_IfThenElseEQ : Program
prog1_IfThenElseEQ = MkProgram IfThenElseEQ Tint (ExpFuncCall (ExpVal 300)) --200

prog2_IfThenElseEQ : Program
prog2_IfThenElseEQ = MkProgram IfThenElseEQ Tint (ExpFuncCall (ExpVal 200)) --200

-- Create a Program that includes the if then else function (not equal) and the necessary return type
prog1_IfThenElseNEQ : Program
prog1_IfThenElseNEQ = MkProgram IfThenElseNEQ Tint (ExpFuncCall (ExpVal 300)) --100

prog2_IfThenElseNEQ : Program
prog2_IfThenElseNEQ = MkProgram IfThenElseNEQ Tint (ExpFuncCall (ExpVal 200)) --100

-- Create a Program value that includes the isEven function and the necessary return type
prog1_isEven : Program
prog1_isEven = MkProgram isEven Tbool (ExpFuncCall (ExpVal 7)) --false

prog2_isEven : Program
prog2_isEven = MkProgram isEven Tbool (ExpFuncCall (ExpVal 8)) --true

prog3_isEven : Program
prog3_isEven = MkProgram isEven Tbool (ExpFuncCall (ExpVal (-7))) --false

prog4_isEven : Program
prog4_isEven = MkProgram isEven Tbool (ExpFuncCall (ExpVal (-8))) --true

-- Create a Program value that includes the isOdd function and the necessary return type
prog1_isOdd : Program
prog1_isOdd = MkProgram isOdd Tbool (ExpFuncCall (ExpVal 7)) --true

prog2_isOdd : Program
prog2_isOdd = MkProgram isOdd Tbool (ExpFuncCall (ExpVal 8)) --false

prog3_isOdd : Program
prog3_isOdd = MkProgram isOdd Tbool (ExpFuncCall (ExpVal (-7))) --true

prog4_isOdd : Program
prog4_isOdd = MkProgram isOdd Tbool (ExpFuncCall (ExpVal (-8))) --false

-- Create a Program value that includes the fib function and the necessary return type
prog1_fib : Program
prog1_fib = MkProgram fib Tint (ExpFuncCall (ExpVal 6)) --8

-- Create a Program value that includes the fact function and the necessary return type
prog1_factorial : Program
prog1_factorial = MkProgram fact Tint (ExpFuncCall (ExpVal 10)) --3628800

---------------------OpenPrograms---------------------

-- Create an OpenProgram value that includes the add function and the necessary return type
openprog1_add1 : OpenProgram
openprog1_add1 = MkOpenProgram Addition1 Tint Tint 100 (ExpFuncCall (ExpVar (StopVar))) --103

openprog1_add2 : OpenProgram
openprog1_add2 = MkOpenProgram Addition2 Tint Tint 20 (ExpFuncCall (ExpVar (StopVar))) --120

-- Create an OpenProgram value that includes the sub function and the necessary return type
openprog1_sub1 : OpenProgram
openprog1_sub1 = MkOpenProgram Subtraction1 Tint Tint 100 (ExpFuncCall (ExpVar (StopVar))) --97

openprog1_sub2 : OpenProgram
openprog1_sub2 = MkOpenProgram Subtraction2 Tint Tint 20 (ExpFuncCall (ExpVar (StopVar))) --80

-- Create an OpenProgram value that includes the mult function and the necessary return type
openprog1_mult1 : OpenProgram
openprog1_mult1 = MkOpenProgram Multiplication1 Tint Tint 100 (ExpFuncCall (ExpVar (StopVar))) --10000

openprog1_mult2 : OpenProgram
openprog1_mult2 = MkOpenProgram Multiplication2 Tint Tint 20 (ExpFuncCall (ExpVar (StopVar))) --400

-- Create an OpenProgram value that includes the IfThenElseLT function and the necessary return type
openprog1_IfThenElseLT : OpenProgram
openprog1_IfThenElseLT = MkOpenProgram IfThenElseLT Tint Tint 100 (ExpFuncCall (ExpVar (StopVar))) --100

-- Create an OpenProgram value that includes the IfThenElseLTE function and the necessary return type
openprog1_IfThenElseLTE : OpenProgram
openprog1_IfThenElseLTE = MkOpenProgram IfThenElseLTE Tint Tint 100 (ExpFuncCall (ExpVar (StopVar))) --100

-- Create an OpenProgram value that includes the IfThenElseGT function and the necessary return type
openprog1_IfThenElseGT : OpenProgram
openprog1_IfThenElseGT = MkOpenProgram IfThenElseGT Tint Tint 100 (ExpFuncCall (ExpVar (StopVar))) --100

-- Create an OpenProgram value that includes the IfThenElseGTE function and the necessary return type
openprog1_IfThenElseGTE : OpenProgram
openprog1_IfThenElseGTE = MkOpenProgram IfThenElseGTE Tint Tint 100 (ExpFuncCall (ExpVar (StopVar))) --100

-- Create an OpenProgram value that includes the IfThenElseEQ function and the necessary return type
openprog1_IfThenElseEQ : OpenProgram
openprog1_IfThenElseEQ = MkOpenProgram IfThenElseEQ Tint Tint 100 (ExpFuncCall (ExpVar (StopVar))) --100

-- Create an OpenProgram value that includes the IfThenElseNEQ function and the necessary return type
openprog1_IfThenElseNEQ : OpenProgram
openprog1_IfThenElseNEQ = MkOpenProgram IfThenElseNEQ Tint Tint 100 (ExpFuncCall (ExpVar (StopVar))) --100

-- Create an OpenProgram value that includes the isEven function and the necessary return type
openprog1_isEven : OpenProgram
openprog1_isEven = MkOpenProgram isEven Tbool Tint 7 (ExpFuncCall (ExpVar (StopVar))) --false

openprog2_isEven : OpenProgram
openprog2_isEven = MkOpenProgram isEven Tbool Tint 8 (ExpFuncCall (ExpVar (StopVar))) --true

openprog3_isEven : OpenProgram
openprog3_isEven = MkOpenProgram isEven Tbool Tint (-7) (ExpFuncCall (ExpVar (StopVar))) --false

openprog4_isEven : OpenProgram
openprog4_isEven = MkOpenProgram isEven Tbool Tint (-8) (ExpFuncCall (ExpVar (StopVar))) --true

-- Create an OpenProgram value that includes the isOdd function and the necessary return type
openprog1_isOdd : OpenProgram
openprog1_isOdd = MkOpenProgram isOdd Tbool Tint 7 (ExpFuncCall (ExpVar (StopVar))) --true

openprog2_isOdd : OpenProgram
openprog2_isOdd = MkOpenProgram isOdd Tbool Tint 8 (ExpFuncCall (ExpVar (StopVar))) --false

openprog3_isOdd : OpenProgram
openprog3_isOdd = MkOpenProgram isOdd Tbool Tint (-7) (ExpFuncCall (ExpVar (StopVar))) --true

openprog4_isOdd : OpenProgram
openprog4_isOdd = MkOpenProgram isOdd Tbool Tint (-8) (ExpFuncCall (ExpVar (StopVar))) --false

-- Create an OpenProgram value that includes the fib function and the necessary return type
openprog1_fib : OpenProgram
openprog1_fib = MkOpenProgram fib Tint Tint 6 (ExpFuncCall (ExpVar (StopVar))) --8

-- Create an OpenProgram value that includes the fact function and the necessary return type
openprog1_fact : OpenProgram
openprog1_fact = MkOpenProgram fact Tint Tint 5 (ExpFuncCall (ExpVar (StopVar))) --120

-- Create an OpenProgram value that includes the squareOrInput function and the necessary return type
openprog1_squareOrInput : OpenProgram
openprog1_squareOrInput = MkOpenProgram squareOrInput Tint Tint 1 (ExpIfThenElse (ExpGreaterThan (ExpVal 2) (ExpVal 1)) (ExpMultiplication (ExpVal 2) (ExpVal 2)) (ExpVal 1))

---------------------Tests program---------------------

-- Write a test that sees if the evaluation of the Program prog1_add1 works as expected
test_prog1_add1 : So (evalProg CompNoCom.prog1_add1 == 103)
test_prog1_add1 = Oh

test_prog1_add2 : So (evalProg CompNoCom.prog2_add1 == 100)
test_prog1_add2 = Oh

-- Write a test that sees if the evaluation of the Program prog1_sub1 works as expected
test_prog1_sub1 : So (evalProg CompNoCom.prog1_sub1 == -97)
test_prog1_sub1 = Oh

test_prog2_sub1 : So (evalProg CompNoCom.prog2_sub1 == -100)
test_prog2_sub1 = Oh

-- Write a test that sees if the evaluation of the Program prog1_mul1 works as expected
test_prog1_mult1 : So (evalProg CompNoCom.prog1_mul1 == 300)
test_prog1_mult1 = Oh

test_prog2_mult1 : So (evalProg CompNoCom.prog2_mul1 == 0)
test_prog2_mult1 = Oh

-- Write a test that sees if the evaluation of the Program prog1_IfThenElseLT works as expected
test_prog1_IfThenElseLT : So (evalProg CompNoCom.prog1_IfThenElseLT == 200)
test_prog1_IfThenElseLT = Oh

test_prog2_IfThenElseLT : So (evalProg CompNoCom.prog2_IfThenElseLT == 100)
test_prog2_IfThenElseLT = Oh

-- Write a test that sees if the evaluation of the Program prog1_IfThenElseLTE works as expected
test_prog1_IfThenElseLTE : So (evalProg CompNoCom.prog1_IfThenElseLTE == 200)
test_prog1_IfThenElseLTE = Oh

test_prog2_IfThenElseLTE : So (evalProg CompNoCom.prog2_IfThenElseLTE == 100)
test_prog2_IfThenElseLTE = Oh

-- Write a test that sees if the evaluation of the Program prog1_IfThenElseGT works as expected
test_prog1_IfThenElseGT : So (evalProg CompNoCom.prog1_IfThenElseGT == 100)
test_prog1_IfThenElseGT = Oh

test_prog2_IfThenElseGT : So (evalProg CompNoCom.prog2_IfThenElseGT == 200)
test_prog2_IfThenElseGT = Oh

-- Write a test that sees if the evaluation of the Program prog1_IfThenElseGTE works as expected
test_prog1_IfThenElseGTE : So (evalProg CompNoCom.prog1_IfThenElseGTE == 100)
test_prog1_IfThenElseGTE = Oh

test_prog2_IfThenElseGTE : So (evalProg CompNoCom.prog2_IfThenElseGTE == 200)
test_prog2_IfThenElseGTE = Oh

-- Write a test that sees if the evaluation of the Program prog1_IfThenElseEQ works as expected
test_prog1_IfThenElseEQ : So (evalProg CompNoCom.prog1_IfThenElseEQ == 200)
test_prog1_IfThenElseEQ = Oh

test_prog2_IfThenElseEQ : So (evalProg CompNoCom.prog2_IfThenElseEQ == 200)
test_prog2_IfThenElseEQ = Oh

-- Write a test that sees if the evaluation of the Program prog1_IfThenElseNEQ works as expected
test_prog1_IfThenElseNEQ : So (evalProg CompNoCom.prog1_IfThenElseNEQ == 100)
test_prog1_IfThenElseNEQ = Oh

test_prog2_IfThenElseNEQ : So (evalProg CompNoCom.prog2_IfThenElseNEQ == 100)
test_prog2_IfThenElseNEQ = Oh

-- Write a test that sees if the evaluation of the Program prog1_isEven works as expected
test_prog1_isEven : So (evalProg CompNoCom.prog1_isEven == False)
test_prog1_isEven = Oh

test_prog2_isEven : So (evalProg CompNoCom.prog2_isEven == True)
test_prog2_isEven = Oh

test_prog3_isEven : So (evalProg CompNoCom.prog3_isEven == False)
test_prog3_isEven = Oh

test_prog4_isEven : So (evalProg CompNoCom.prog4_isEven == True)
test_prog4_isEven = Oh

-- Write a test that sees if the evaluation of the Program prog1_isOdd works as expected
test_prog1_isOdd : So (evalProg CompNoCom.prog1_isOdd == True)
test_prog1_isOdd = Oh

test_prog2_isOdd : So (evalProg CompNoCom.prog2_isOdd == False)
test_prog2_isOdd = Oh

test_prog3_isOdd : So (evalProg CompNoCom.prog3_isOdd == True)
test_prog3_isOdd = Oh

test_prog4_isOdd : So (evalProg CompNoCom.prog4_isOdd == False)
test_prog4_isOdd = Oh

-- Write a test that sees if the evaluation of the Program prog1_fib works as expected
test_prog1_fib : So (evalProg CompNoCom.prog1_fib == 8)
test_prog1_fib = Oh

-- Write a test that sees if the evaluation of the Program prog1_factorial works as expected
test_prog1_factorial : So (evalProg CompNoCom.prog1_factorial == 3628800)
test_prog1_factorial = Oh

---------------------Tests open program---------------------
-- Write a test that sees if the evaluation of the Program fibProg is equal to 8
test6 : Bool
test6 = evalOpenProg openprog1_fib == 8

test2 : Bool
test2 = evalOpenProg openprog1_add2 == 4

test3 : Bool
test3 = evalOpenProg openprog1_squareOrInput == 4


---------------------Ackermann---------------------
ackermann : Exp vEnv fEnv Tint -> Exp vEnv fEnv Tint -> Exp vEnv fEnv Tint
ackermann m n =
  ExpIfThenElse (ExpEqual m (ExpVal 0))
    (ExpAddition n (ExpVal 1))
    (ExpIfThenElse (ExpEqual n (ExpVal 0))
      (ackermann m (ExpVal 1))
      (ackermann m (ackermann (ExpAddition m (ExpVal 1)) n)))
