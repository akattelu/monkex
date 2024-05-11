defmodule ParserTest do
  use ExUnit.Case
  alias Monkex.AST.BlockStatement
  alias Monkex.AST.Expression
  alias Monkex.AST.Statement
  alias Monkex.AST.IfExpression
  alias Monkex.AST.LetStatement
  alias Monkex.AST.InfixExpression
  alias Monkex.AST.ExpressionStatement
  alias Monkex.AST.IntegerLiteral
  alias Monkex.AST.BooleanLiteral
  alias Monkex.AST.StringLiteral
  alias Monkex.AST.Identifier
  alias Monkex.AST.Program
  alias Monkex.Lexer
  alias Monkex.Parser
  alias Monkex.Token

  test "ast string" do
    program = %Program{
      statements: [
        %LetStatement{
          token: %Token{type: :let, literal: "let"},
          name: %Identifier{token: %Token{type: :ident, literal: "myVar"}, symbol_name: "myVar"},
          value: %Identifier{
            token: %Token{type: :ident, literal: "anotherVar"},
            symbol_name: "anotherVar"
          }
        }
      ]
    }

    assert "#{program}" == "let myVar = anotherVar;"
  end

  test "parse let statements" do
    input = """
    let x = 5;
    let y = 10;
    let foobar = 838383;
    """

    parser = input |> Lexer.new() |> Parser.new()

    {final, program} = Parser.parse_program(parser)

    if length(final.errors) != 0 do
      assert length(final.errors |> IO.inspect()) == 0
    end

    assert program != nil
    assert length(program.statements) == 3

    [{"x", 5}, {"y", 10}, {"foobar", 838_383}]
    |> Stream.with_index()
    |> Enum.map(fn {{input, output}, index} ->
      test_let_statement(Enum.at(program.statements, index), input, output)
    end)
  end

  test "parse return statements" do
    input = """
    return 5;
    return 10;
    return 838383;
    """

    expected = [5, 10, 838_383]

    parser = input |> Lexer.new() |> Parser.new()

    {final, program} = Parser.parse_program(parser)

    if length(final.errors) != 0 do
      assert length(final.errors |> IO.inspect()) == 0
    end

    assert program != nil
    assert length(program.statements) == 3

    Enum.zip(program.statements, expected)
    |> Enum.map(fn {s, out} ->
      assert Statement.token_literal(s) == "return"
      assert s.return_value.value == out
    end)
  end

  test "test expression statements" do
    {parser, program} =
      "foobar;"
      |> Lexer.new()
      |> Parser.new()
      |> Parser.parse_program()

    assert parser.errors == []

    assert program.statements == [
             %ExpressionStatement{
               token: %Token{type: :ident, literal: "foobar"},
               expression: %Identifier{
                 token: %Token{type: :ident, literal: "foobar"},
                 symbol_name: "foobar"
               }
             }
           ]
  end

  test "parse integer literal" do
    {parser, program} =
      "99;"
      |> Lexer.new()
      |> Parser.new()
      |> Parser.parse_program()

    assert parser.errors == []

    assert program.statements == [
             %ExpressionStatement{
               token: %Token{type: :int, literal: "99"},
               expression: %IntegerLiteral{
                 token: %Token{type: :int, literal: "99"},
                 value: 99
               }
             }
           ]
  end

  test "parse boolean literal" do
    {parser, program} =
      "true;
      false;"
      |> Lexer.new()
      |> Parser.new()
      |> Parser.parse_program()

    assert parser.errors == []

    assert program.statements == [
             %ExpressionStatement{
               token: %Token{type: true, literal: "true"},
               expression: %BooleanLiteral{
                 token: %Token{type: true, literal: "true"},
                 value: true
               }
             },
             %ExpressionStatement{
               token: %Token{type: false, literal: "false"},
               expression: %BooleanLiteral{
                 token: %Token{type: false, literal: "false"},
                 value: false
               }
             }
           ]
  end

  test "parse string literals" do
    {parser, program} =
      """
        "hello world";
      """
      |> Lexer.new()
      |> Parser.new()
      |> Parser.parse_program()

    assert parser.errors == []

    assert program.statements == [
             %ExpressionStatement{
               token: %Token{type: :string, literal: "hello world"},
               expression: %StringLiteral{
                 token: %Token{type: :string, literal: "hello world"},
                 value: "hello world"
               }
             }
           ]
  end

  test "parse prefix and integer literal expressions" do
    inputs = [
      "!5",
      "-15"
    ]

    expected = [
      {"!", 5},
      {"-", 15}
    ]

    Enum.zip(inputs, expected)
    |> Enum.each(fn {input, {op, val}} ->
      {parser, program} =
        input
        |> Lexer.new()
        |> Parser.new()
        |> Parser.parse_program()

      assert parser.errors == []
      assert length(program.statements) == 1

      program.statements
      |> hd()
      |> then(fn s ->
        assert Expression.token_literal(s.expression) == op
        assert s.expression.operator == op
        assert s.expression.right.value == val
      end)
    end)
  end

  test "parse infix literal expressions" do
    inputs = [
      "5 + 5;",
      "5 - 5;",
      "5 * 5;",
      "5 / 5;",
      "5 > 5;",
      "5 < 5;",
      "5 == 5;",
      "5 != 5;"
    ]

    expected = [
      {5, "+", 5},
      {5, "-", 5},
      {5, "*", 5},
      {5, "/", 5},
      {5, ">", 5},
      {5, "<", 5},
      {5, "==", 5},
      {5, "!=", 5}
    ]

    Enum.zip(inputs, expected)
    |> Enum.each(fn {input, {left, op, right}} ->
      {parser, program} =
        input
        |> Lexer.new()
        |> Parser.new()
        |> Parser.parse_program()

      assert parser.errors == []
      assert length(program.statements) == 1

      program.statements
      |> hd()
      |> then(fn s ->
        assert s.expression.left.value == left
        assert s.expression.operator == op
        assert s.expression.right.value == right
      end)
    end)
  end

  test "parse infix expressions with precedence" do
    tests = [
      {
        "-a * b",
        "((-a) * b)"
      },
      {
        "!-a",
        "(!(-a))"
      },
      {
        "a + b + c",
        "((a + b) + c)"
      },
      {
        "a + b - c",
        "((a + b) - c)"
      },
      {
        "a * b * c",
        "((a * b) * c)"
      },
      {
        "a * b / c",
        "((a * b) / c)"
      },
      {
        "a + b / c",
        "(a + (b / c))"
      },
      {
        "a + b * c + d / e - f",
        "(((a + (b * c)) + (d / e)) - f)"
      },
      {
        "3 + 4; -5 * 5",
        "(3 + 4)((-5) * 5)"
      },
      {
        "a + add(b * c) + d",
        "((a + add((b * c))) + d)"
      },
      {
        "add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))",
        "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"
      },
      {
        "add(a + b + c * d / f + g)",
        "add((((a + b) + ((c * d) / f)) + g))"
      }
    ]

    tests
    |> Enum.map(fn {input, expected} ->
      {_, program} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()

      assert "#{program}" == expected
    end)
  end

  test "parses grouped expressions" do
    inputs = [
      "(5 + 5)",
      "(1 + 2) * 3",
      "-(5 + 5)",
      "!(true == true)"
    ]

    expected = [
      "(5 + 5)",
      "((1 + 2) * 3)",
      "(-(5 + 5))",
      "(!(true == true))"
    ]

    Enum.zip(inputs, expected)
    |> Enum.each(fn {input, output} ->
      {parser, program} =
        input
        |> Lexer.new()
        |> Parser.new()
        |> Parser.parse_program()

      assert parser.errors == []
      assert length(program.statements) == 1

      program.statements
      |> hd()
      |> then(fn s ->
        assert "#{s.expression}" == output
      end)
    end)
  end

  test "parse if expressions" do
    input = "if (x < y) { x }"

    expected = %IfExpression{
      token: %Token{type: :if, literal: "if"},
      condition: %InfixExpression{
        token: %Token{type: :lt, literal: "<"},
        left: %Identifier{token: %Token{type: :ident, literal: "x"}, symbol_name: "x"},
        operator: "<",
        right: %Identifier{token: %Token{type: :ident, literal: "y"}, symbol_name: "y"}
      },
      then_block: %BlockStatement{
        token: %Token{type: :lbrace, literal: "{"},
        statements: [
          %ExpressionStatement{
            token: %Token{type: :ident, literal: "x"},
            expression: %Identifier{
              token: %Token{type: :ident, literal: "x"},
              symbol_name: "x"
            }
          }
        ]
      },
      else_block: nil
    }

    {parser, program} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()
    assert parser.errors == []

    assert length(program.statements) == 1

    program.statements
    |> hd
    |> then(fn s ->
      assert s.expression == expected
    end)
  end

  test "parse if else expressions" do
    input = "if (x < y) { x } else { y }"

    expected = %IfExpression{
      token: %Token{type: :if, literal: "if"},
      condition: %InfixExpression{
        token: %Token{type: :lt, literal: "<"},
        left: %Identifier{token: %Token{type: :ident, literal: "x"}, symbol_name: "x"},
        operator: "<",
        right: %Identifier{token: %Token{type: :ident, literal: "y"}, symbol_name: "y"}
      },
      then_block: %BlockStatement{
        token: %Token{type: :lbrace, literal: "{"},
        statements: [
          %ExpressionStatement{
            token: %Token{type: :ident, literal: "x"},
            expression: %Identifier{
              token: %Token{type: :ident, literal: "x"},
              symbol_name: "x"
            }
          }
        ]
      },
      else_block: %BlockStatement{
        token: %Token{type: :lbrace, literal: "{"},
        statements: [
          %ExpressionStatement{
            token: %Token{type: :ident, literal: "y"},
            expression: %Identifier{
              token: %Token{type: :ident, literal: "y"},
              symbol_name: "y"
            }
          }
        ]
      }
    }

    {parser, program} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()
    assert parser.errors == []

    assert length(program.statements) == 1

    program.statements
    |> hd
    |> then(fn s ->
      assert s.expression == expected
    end)
  end

  test "function literal parsing params" do
    tests = [
      {"fn () { };", []},
      {"fn (x) {x};", ["x"]},
      {"fn (x,y) {x};", ["x", "y"]}
    ]

    tests
    |> Enum.each(fn {input, expected} ->
      {parser, program} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()
      assert parser.errors == []

      assert length(program.statements) == 1

      first_statement = program.statements |> hd()
      expression = first_statement.expression

      assert expression.params |> Enum.map(& &1.symbol_name) == expected
    end)
  end

  test "function literal parsing body" do
    tests = [
      {"fn () { };", "{ }"},
      {"fn (x) {x};", "{ x }"},
      {"fn (x,y) {x + y};", "{ (x + y) }"}
    ]

    tests
    |> Enum.each(fn {input, expected} ->
      {parser, program} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()
      assert parser.errors == []

      assert length(program.statements) == 1

      first_statement = program.statements |> hd()
      expression = first_statement.expression

      assert "#{expression.body}" == expected
    end)
  end

  test "parses call expressions" do
    input = "add(1, 2 + 3, 4 * 5);"

    {parser, program} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()
    assert parser.errors == []
    assert program.statements |> length == 1
    call_expr = program.statements |> hd |> then(& &1.expression)

    assert call_expr.function.symbol_name == "add"

    assert call_expr.arguments |> Enum.map(&String.Chars.to_string/1) == [
             "1",
             "(2 + 3)",
             "(4 * 5)"
           ]
  end

  test "errors for array literals" do
    [
      {"[", "expected rbracket, got eof"},
      {"[ 1 2 3]", "expected rbracket, got int"},
      {"[ 1 , ,]", "no prefix function found for ,"}
    ]
    |> Enum.each(fn {input, expected} ->
      {parser, _} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()
      assert expected in parser.errors
    end)
  end

  test "parse array literals" do
    tests = [
      {"[]", []},
      {"[1]", [1]},
      {"[1, 2, 3]", [1, 2, 3]}
    ]

    tests
    |> Enum.each(fn {input, expected} ->
      {parser, program} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()
      assert parser.errors == []
      assert length(program.statements) == 1

      first_statement = program.statements |> hd()
      expression = first_statement.expression

      assert expression.items |> length == expected |> length

      Enum.zip(expression.items, expected)
      |> Enum.each(fn {actual, exp} ->
        assert actual.value == exp
      end)
    end)
  end

  test "parses indexing expressions" do
    input = "arr[2 + 3];"

    {parser, program} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()
    assert parser.errors == []
    assert program.statements |> length == 1
    index_expr = program.statements |> hd |> then(& &1.expression)

    assert index_expr.indexable_expr.symbol_name == "arr"

    assert "#{index_expr.index_expr}" == "(2 + 3)"
  end

  test "parse dictionary literals" do
    input = ~s({"a": 1, "b": true, "c": "hello", "d": [], var: {}, "e": 2 + 3, "f": {"a": 1}})

    expected = [
      {~s("a"), "1"},
      {~s("b"), "true"},
      {~s("c"), ~s("hello")},
      {~s("d"), "[]"},
      {"var", "{ }"},
      {~s("e"), "(2 + 3)"},
      {~s("f"), ~s({ "a": 1 })}
    ]

    {parser, program} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()
    assert parser.errors == []
    assert program.statements |> length == 1
    expr = program.statements |> hd |> then(& &1.expression)

    pairs = expr.pairs

    assert length(pairs) == length(expected)

    pairs
    |> Enum.zip(expected)
    |> Enum.map(fn {pair, {exp_key, exp_val}} ->
      assert "#{exp_key}" == "#{pair.key}"
      assert "#{exp_val}" == "#{pair.value}"
    end)
  end

  def test_let_statement(statement, name, value) do
    assert Statement.token_literal(statement) == "let"
    assert statement.name.symbol_name == name
    assert statement.value.value == value
    assert Expression.token_literal(statement.name) == name
  end
end
