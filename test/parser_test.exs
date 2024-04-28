defmodule ParserTest do
  use ExUnit.Case
  alias Monkex.AST.Expression
  alias Monkex.AST.Statement
  alias Monkex.AST.LetStatement
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
          value: %Identifier{token: %Token{type: :ident, literal: "anotherVar"}, symbol_name: "anotherVar"}
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

  def test_let_statement(statement, name) do
    assert Statement.token_literal(statement) == "let"
    assert statement.name.symbol_name == name
    assert Expression.token_literal(statement.name) == name
  end
end
