defmodule LexerTest do
  use ExUnit.Case
  alias Monkex.Lexer

  test "lex simple number expr with eof" do
    input = "1 + 2"

    expected = [
      {:int, "1"},
      {:plus, "+"},
      {:int, "2"},
      {:eof, ""}
    ]

    expected
    |> Enum.reduce(Lexer.new(input), fn {type, literal}, next_lexer ->
      {l, token} = Lexer.next_token(next_lexer)
      assert token.type == type
      assert token.literal == literal
      l
    end)
  end

  test "next token with single char" do
    input = "=+(){},;[]"

    expected = [
      {:assign, "="},
      {:plus, "+"},
      {:lparen, "("},
      {:rparen, ")"},
      {:lbrace, "{"},
      {:rbrace, "}"},
      {:comma, ","},
      {:semicolon, ";"},
      {:lbracket, "["},
      {:rbracket, "]"}
    ]

    expected
    |> Enum.reduce(Lexer.new(input), fn {type, literal}, next_lexer ->
      {l, token} = Lexer.next_token(next_lexer)
      assert token.type == type
      assert token.literal == literal
      l
    end)
  end

  test "next token with source" do
    input = """
    let five = 5;
    let ten = 10;

    let add = fn(x, y) {
      x + y;
    };

    let result = add(five, ten);
    """

    expected = [
      {:let, "let"},
      {:ident, "five"},
      {:assign, "="},
      {:int, "5"},
      {:semicolon, ";"},
      {:let, "let"},
      {:ident, "ten"},
      {:assign, "="},
      {:int, "10"},
      {:semicolon, ";"},
      {:let, "let"},
      {:ident, "add"},
      {:assign, "="},
      {:function, "fn"},
      {:lparen, "("},
      {:ident, "x"},
      {:comma, ","},
      {:ident, "y"},
      {:rparen, ")"},
      {:lbrace, "{"},
      {:ident, "x"},
      {:plus, "+"},
      {:ident, "y"},
      {:semicolon, ";"},
      {:rbrace, "}"},
      {:semicolon, ";"},
      {:let, "let"},
      {:ident, "result"},
      {:assign, "="},
      {:ident, "add"},
      {:lparen, "("},
      {:ident, "five"},
      {:comma, ","},
      {:ident, "ten"},
      {:rparen, ")"},
      {:semicolon, ";"}
    ]

    expected
    |> Enum.reduce(Lexer.new(input), fn {type, literal}, next_lexer ->
      {l, token} = Lexer.next_token(next_lexer)
      assert token.type == type
      assert token.literal == literal
      l
    end)
  end

  test "extra symbols" do
    input = """
    let five = 5;
    let ten = 10;

    let add = fn(x, y) {
      x + y;
    };

    let result = add(five, ten);
    !-/*5;
    5 < 10 > 5;

    if (5 < 10) {
        return true;
    } else {
        return false;
    }

    10 == 10;
    10 != 9;
    "foobar";
    "foo bar";
    "";
    """

    expected = [
      {:let, "let"},
      {:ident, "five"},
      {:assign, "="},
      {:int, "5"},
      {:semicolon, ";"},
      {:let, "let"},
      {:ident, "ten"},
      {:assign, "="},
      {:int, "10"},
      {:semicolon, ";"},
      {:let, "let"},
      {:ident, "add"},
      {:assign, "="},
      {:function, "fn"},
      {:lparen, "("},
      {:ident, "x"},
      {:comma, ","},
      {:ident, "y"},
      {:rparen, ")"},
      {:lbrace, "{"},
      {:ident, "x"},
      {:plus, "+"},
      {:ident, "y"},
      {:semicolon, ";"},
      {:rbrace, "}"},
      {:semicolon, ";"},
      {:let, "let"},
      {:ident, "result"},
      {:assign, "="},
      {:ident, "add"},
      {:lparen, "("},
      {:ident, "five"},
      {:comma, ","},
      {:ident, "ten"},
      {:rparen, ")"},
      {:semicolon, ";"},
      {:bang, "!"},
      {:minus, "-"},
      {:slash, "/"},
      {:asterisk, "*"},
      {:int, "5"},
      {:semicolon, ";"},
      {:int, "5"},
      {:lt, "<"},
      {:int, "10"},
      {:gt, ">"},
      {:int, "5"},
      {:semicolon, ";"},
      {:if, "if"},
      {:lparen, "("},
      {:int, "5"},
      {:lt, "<"},
      {:int, "10"},
      {:rparen, ")"},
      {:lbrace, "{"},
      {:return, "return"},
      {true, "true"},
      {:semicolon, ";"},
      {:rbrace, "}"},
      {:else, "else"},
      {:lbrace, "{"},
      {:return, "return"},
      {false, "false"},
      {:semicolon, ";"},
      {:rbrace, "}"},
      {:int, "10"},
      {:eq, "=="},
      {:int, "10"},
      {:semicolon, ";"},
      {:int, "10"},
      {:not_eq, "!="},
      {:int, "9"},
      {:semicolon, ";"},
      {:string, "foobar"},
      {:semicolon, ";"},
      {:string, "foo bar"},
      {:semicolon, ";"},
      {:string, ""},
      {:semicolon, ";"}
    ]

    expected
    |> Enum.reduce(Lexer.new(input), fn {type, literal}, next_lexer ->
      {l, token} = Lexer.next_token(next_lexer)
      assert token.literal == literal
      assert token.type == type
      l
    end)
  end

  test "next token for dictionary" do
    input = """
    let x = {
      "a": 1,
      "b": true,
      "c": "hello"
    }
    """
    expected = [
      {:let, "let"},
      {:ident, "x"},
      {:assign, "="},
      {:lbrace, "{"},
      {:string, "a"},
      {:colon, ":"},
      {:int, "1"},
      {:comma, ","},
      {:string, "b"},
      {:colon, ":"},
      {true, "true"},
      {:comma, ","},
      {:string, "c"},
      {:colon, ":"},
      {:string, "hello"},
      {:rbrace, "}"}
    ]
    expected
    |> Enum.reduce(Lexer.new(input), fn {type, literal}, next_lexer ->
      {l, token} = Lexer.next_token(next_lexer)
      assert token.literal == literal
      assert token.type == type
      l
    end)

    end
end
