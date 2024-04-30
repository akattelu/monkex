defmodule ParserTest do
  use ExUnit.Case
  alias Monkex.AST.Expression
  alias Monkex.AST.Statement
  alias Monkex.AST.LetStatement
  alias Monkex.AST.ExpressionStatement
  alias Monkex.AST.IntegerLiteral
  alias Monkex.AST.BooleanLiteral
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

    ["x", "y", "foobar"]
    |> Stream.with_index()
    |> Enum.map(fn {item, index} ->
      test_let_statement(Enum.at(program.statements, index), item)
    end)
  end

  test "parse return statements" do
    input = """
    return 5;
    return 10;
    return 838383;
    """

    parser = input |> Lexer.new() |> Parser.new()

    {final, program} = Parser.parse_program(parser)

    if length(final.errors) != 0 do
      assert length(final.errors |> IO.inspect()) == 0
    end

    assert program != nil
    assert length(program.statements) == 3

    program.statements
    |> Enum.map(fn s ->
      assert Statement.token_literal(s) == "return"
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

  def test_let_statement(statement, name) do
    assert Statement.token_literal(statement) == "let"
    assert statement.name.symbol_name == name
    assert Expression.token_literal(statement.name) == name
  end
end
