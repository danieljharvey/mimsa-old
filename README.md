# mimsa

very small language. pls be gentle.

```bash
stack install
stack exec mimsa
```

you should then see:

```bash
~~~ MIMSA ~~~
:help - this help screen
:info <expr> - get the type of <expr>
:bind <name> = <expr> - binds <expr> to <name> and saves it in the environment
:list - show a list of current bindings in the environment
:quit - give up and leave
<expr> - evaluate <expr>, returning it's simplified form and type
```

syntax (incomplete):

literals:

```haskell
:> True
True :: Boolean

:> False
False :: Boolean

:> 1
1 :: Int

:> 56
56 :: Int

:> 234234
234234 :: Int

:> "dog"
"dog" :: String

:> "horse"
"horse" :: String
```

if statements:

```haskell
:> if True then 1 else 2
1 :: Int

:> if False then 1 else 2
2 :: Int

-- returning type should always match on both sides
:> if False then 1 else "dog"
Unification error: Can't match MTInt with MTString
```

lambdas and function application:

```haskell
:> :bind id = \x -> x
Bound id to \x -> x :: U1 -> U1

:> id(1)
1 :: Int

:> :bind const = \x -> \y -> x
Bound const to \x -> (\y -> x) :: U1 -> (U2 -> U1)

:> const(2)("horse")
2 :: Int

:> :bind compose = \f -> \g -> \a -> f(g(a))
Bound compose to \f -> (\g -> (\a -> (f(g(a))))) :: (U5 -> U4) -> ((U3 -> U5) -> (U3 -> U4))
```

pairs:

```haskell
:> (1, "horse")
(1, "horse") :: (Int, String)

:> :bind fst = \x -> let (a, b) = x in a
Bound fst to \x -> let (a, b) = x in a :: (U2, U3) -> U2

:> fst((1,"horse"))
1 :: Int
```
