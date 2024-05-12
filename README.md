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
1. Variable binding with `let` and returning values with `return`
1. Conditional statements with `if`/`else`
1. Dynamic typing
1. Evaluation via REPL or `.mx` files


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
# 55

./monkex ./examples/string_split.mx
# ["hello", "world", "again"]

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


The REPL can also take the `--lex` or `--parse` args to run the REPL as intermediate phases of the interpreter:

```sh
monkex main* 2s λ  ./monkex --lex
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
monkex main* 8s λ  ./monkex --parse
>> let a = 1 + 2 -3;
let a = ((1 + 2) - 3);
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
./monkex ./examples/fib.mx
# 55
```

### Launch REPL

```sh
mix repl
mix repl --lex
mix repl --parse
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
                                                                                                                          
Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
reduction time: 0 ns
parallel: 1
inputs: none specified
Estimated total run time: 49 s
                                                                                                                          
Benchmarking evaluate.fib10 ...
Benchmarking evaluate.string_split ...
Benchmarking parse ...
Benchmarking parse_and_evaluate.cube ...
Benchmarking parse_and_evaluate.fib10 ...
Benchmarking parse_and_evaluate.string_split ...
Benchmarking tokenize ...
Calculating statistics...
Formatting results...
                                                                                                                          
Name                                      ips        average  deviation         median         99th %
evaluate.string_split                 5925.59       0.169 ms     ±5.93%       0.167 ms        0.21 ms
evaluate.fib10                        3757.81        0.27 ms     ±3.04%        0.26 ms        0.30 ms
parse_and_evaluate.fib10              1351.72        0.74 ms     ±3.83%        0.74 ms        0.84 ms
parse                                  162.97        6.14 ms     ±0.94%        6.12 ms        6.33 ms
parse_and_evaluate.string_split        158.95        6.29 ms     ±2.20%        6.30 ms        6.63 ms
tokenize                               155.31        6.44 ms     ±6.49%        6.35 ms        7.58 ms
parse_and_evaluate.cube                  1.66      601.84 ms     ±0.42%      602.47 ms      606.00 ms
```
