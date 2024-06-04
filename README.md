# MonkEx

Elixir implementation of the Monkey programming language

<img src="https://github.com/akattelu/monkex/assets/12012201/1ca3de7e-e41d-418a-be30-67a57b54c47b" width=300 height=300 />

## Examples

```
let fibonacci = fn(x) {
  if (x == 0) {
    0
  } else {
    if (x == 1) {
      1
    } else {
      fibonacci(x - 1) + fibonacci(x - 2);
    }
  }
};
```

See more [examples](./examples)

## Features

1. Booleans, integers, and strings as primitive data types
1. Arrays and dictionaries and data structures
1. Functions as values, recursion, and higher order functions
1. Closures over functions
1. Variable binding with `let` and returning values with `return`
1. Conditional statements with `if`/`else`
1. Dynamic typing
1. Evaluation via REPL or `.mx` files
1. A tree-sitter grammar for syntax highlighting in modern editors


## Usage

You can build `monkex` into a standalone escript

```
mix escript.build
./monkex
```

## Evaluating a file

You can run `monkex` against a .mx file to evaluate it
```sh
./monkex ./examples/fib.mx
# 6765

./monkex ./examples/cube.mx # advent of code 2023 day 2 part 1
# 3059
```

## REPL

The REPL is a good way to play around with the language and its features. Running `monkex` without arguments starts the REPL.

```
monkex main* λ  ./monkex
>> let a = 3;
3
>> a + 5;
8
>> let addTen = fn (x) { x + 10 };
fn(x) { (x + 10) }
>> addTen(a);
13
>> let arr = [20, "hello", true];
[20, "hello", true]
>> let dict = {"hello": 42};
{"hello": 42}
>> dict[arr[1]];
42
>> addTen(dict[arr[1]]);
52
>> ⏎
```

The REPL also provides error messages in case of parsing or runtime failures:

```sh
monkex main* 2s λ  ./monkex
>> let a 3

Woops! We ran into some monkey business here!
            __,__
   .--.  .-"     "-.  .--.
  / .. \/  .-. .-.  \/ .. \
 | |  '|  /   Y   \  |'  | |
 | \   \  \ X___X /  /   / |
  \ '- ,\.-"""""""-./, -' /
   ''-' /_   ^ ^   _\ '-''
       |  \._____./  |
       \   \     /   /
        '._ '-=-' _.'
           '-----'

Here are the parser errors:
         - expected assign, got int
>> let a = 3;
3
>> a + b;
Error: identifier not found: b
```


The REPL can also take the `--lex`, `--parse` or `--bytecode` args to run the REPL as intermediate phases of the interpreter:

```sh
λ ./monkex --lex
>> let a = 1 + 2;
token type: let, literal: let
token type: ident, literal: a
token type: assign, literal: =
token type: int, literal: 1
token type: plus, literal: +
token type: int, literal: 2
token type: semicolon, literal: ;
>> ⏎
```

```sh
λ ./monkex --parse
>> let a = 1 + 2 -3;
let a = ((1 + 2) - 3);
>> ⏎
```

```sh
λ ./monkex --bytecode
>> let a = 1 + 2 - 3;
0000 OpConstant 0
0003 OpConstant 1
0006 OpAdd
0007 OpConstant 2
0010 OpSub
0011 OpSetGlobal 0
>> ⏎
```

You can input a newline or C-d to exit the REPL


## Programming in MonkEx

### List of builtin functions
1. `head/1`
1. `tail/1`
1. `last/1`
1. `len/1`
1. `push/2`
1. `cons/2`
1. `puts/1`
1. `read/1`
1. `readLines/1`
1. `parseInt/1`
1. `charAt/2`

## Developing

MonkEx depends on elixir and mix

### Run Tests

```sh
mix test
```

### Compile to standalone escript
```sh
mix escript.build
./monkex ./examples/fib.mx # uses bytecode vm
# 55
```

### Launch REPL

```sh
mix repl # evaluate with tree-walking interpreter
mix repl --lex # output tokens
mix repl --parse # output string representation of AST
mix repl --bytecode # output compiled bytecode
mix repl --vm # evaluate with compilation + vm
```

### Evaluate a file 
```sh
mix mx ./examples/fib.mx
# 55
```

## Benchmarking

This repo uses https://github.com/bencheeorg/benchee for benchmarking. You can run benchmarks with `mix run bench/bench.exs`

Here are some results from my machine:

```sh
Operating System: macOS
CPU Information: Apple M2 Pro
Number of Available Cores: 10
Available memory: 32 GB
Elixir 1.16.2
Erlang 26.2.4
JIT enabled: true

##### With input cube #####
Name                                ips        average  deviation         median         99th %
compile                           11.74       85.21 ms    ±16.64%       83.04 ms      156.11 ms
parse                             11.29       88.57 ms    ±13.53%       86.35 ms      131.76 ms
tokenize                           9.24      108.27 ms    ±11.39%      107.17 ms      145.53 ms
evaluate with interpreter          1.24      805.94 ms     ±3.84%      801.35 ms      895.81 ms
evaluate with vm                   0.48     2087.66 ms     ±2.01%     2081.62 ms     2173.43 ms
                                                                                                                                                         
##### With input fib #####
Name                                ips        average  deviation         median         99th %
tokenize                         2.09 K      477.54 μs   ±128.68%      326.09 μs     2608.56 μs
parse                            1.93 K      518.80 μs    ±93.29%      390.46 μs     2321.65 μs
compile                          1.91 K      522.74 μs    ±58.46%      464.96 μs     1434.75 μs
evaluate with interpreter      0.0234 K    42646.28 μs    ±12.70%    42159.71 μs    57612.73 μs
evaluate with vm              0.00575 K   173841.74 μs     ±9.40%   171212.17 μs   234320.35 μs
                                                                                                                                                         
##### With input hof #####
Name                                ips        average  deviation         median         99th %
compile                           10.61       94.22 ms    ±10.51%       93.33 ms      123.29 ms
parse                             10.48       95.42 ms    ±16.17%       93.55 ms      170.13 ms
evaluate with interpreter         10.37       96.40 ms     ±8.96%       96.08 ms      121.46 ms
evaluate with vm                  10.04       99.59 ms     ±9.15%       98.59 ms      130.61 ms
tokenize                           8.53      117.25 ms    ±14.39%      115.36 ms      194.31 ms
```

The bytecode VM is actually slower than the interpreter for the most part, even if you exclude
compilation time...! This could definitely be improved in the future, and is mostly due to heavy
use of recursion, immutable structures, and O(n) lookup time for some internal data structures.
