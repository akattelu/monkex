defmodule ParserTest do
  use ExUnit.Case
  alias Monkex.AST.Expression
  alias Monkex.Lexer
  alias Monkex.Parser
  alias Monkex.AST.Statement

  test "parse let statements" do
    input = """
    let x = 5;
    let y = 10;
    let foobar = 838383;
    """

    parser = input |> Lexer.new() |> Parser.new()

    program = Parser.parse_program(parser)
    assert program != nil
    assert length(program.statements) == 3

    ["x", "y", "foobar"]
    |> Stream.with_index()
    |> Enum.map(fn {item, index} ->
      test_let_statement(program.statements[index], item)
    end)
  end

  def test_let_statement(statement, name) do
    assert Statement.token_literal(statement) == "let"
    assert statement.name.symbol_name == name
    assert Expression.token_literal(statement.name) == name
  end
end
