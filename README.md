# MonkEx

Elixir verison of Monkey: a toy programming language implemented for learning purposes

# Features


## REPL

MonkEx features a functional REPL

To start the REPL:

```sh
mix repl
```

The REPL is a good way to play around with the language and its features:

```sh
$ mix repl
Hello aakash, this is MonkEx
Feel free to type in some commands!
                                                                                                                                                  
>> let x = 3;
3
>> x + 5;
8
>> let add_three = fn(y) { x + y };
fn(y) { (x + y) }
>> add_three(10);
13

```

The REPL also outputs parser errors and runtime errors: 

```sh
$ mix repl
Hello aakash, this is MonkEx
Feel free to type in some commands!

>> let a 3;

Woops! We ran into some monkey business here!
            __,__
   .--.  .-"     "-.  .--.
  / .. \/  .-. .-.  \/ .. \
 | |  '|  /   Y   \  |'  | |
 | \   \  \ x | x /  /   / |
  \ '- ,\.-"""""""-./, -' /
   ''-' /_   ^ ^   _\ '-''
       |  \._   _./  |
       \   \ '~' /   /
        '._ '-=-' _.'
           '-----'

Here are the parser errors:
         - expected assign, got int
>> let a = 3;
3
>> a + b;
Error: identifier not found: b

```

The REPL can also be run in lexer (`--lex`) or parser (`--parse`) mode for debugging purposes:

```sh
$ mix repl --lex
Hello aakash, this is MonkEx
Feel free to type in some commands!
                                                                                                                                                  
>> a + b;
%Monkex.Token{type: :ident, literal: "a"}
%Monkex.Token{type: :plus, literal: "+"}
%Monkex.Token{type: :ident, literal: "b"}
%Monkex.Token{type: :semicolon, literal: ";"}
>> fn (a) { a + 5 } ;
%Monkex.Token{type: :function, literal: "fn"}
%Monkex.Token{type: :lparen, literal: "("}
%Monkex.Token{type: :ident, literal: "a"}
%Monkex.Token{type: :rparen, literal: ")"}
%Monkex.Token{type: :lbrace, literal: "{"}
%Monkex.Token{type: :ident, literal: "a"}
%Monkex.Token{type: :plus, literal: "+"}
%Monkex.Token{type: :int, literal: "5"}
%Monkex.Token{type: :rbrace, literal: "}"}
%Monkex.Token{type: :semicolon, literal: ";"}
```
```sh
$ mix repl --parse
Hello aakash, this is MonkEx
Feel free to type in some commands!
                                                                                                                                                  
>> a + b;
(a + b)
>> fn (a) { a + 5 };
fn (a) { (a + 5) }
>> a + b + c;
((a + b) + c)
```

You can input a newline or C-d to exit the REPL


# Developing

MonkEx depends on elixir and mix

## Run Tests

```sh
mix test
```

<!-- 
# Learnings


## Evaluator

Having an immutable environment helped a lot when supporting closures. You can see the implementation in [the call expression AST node](./lib/ast/call_expression.ex)

-->
