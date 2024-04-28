defmodule Monkex.Parser do
  alias Monkex.Lexer
  alias Monkex.AST
  @enforce_keys [:lexer, :current_token, :next_token]
  defstruct [:lexer, :current_token, :next_token]

  @type t :: %__MODULE__{
          lexer: Monkex.Lexer.t(),
          current_token: Monkex.Token.t() | nil,
          next_token: Monkex.Token.t() | nil
        }

  @spec new(Monkex.Lexer.t()) :: t
  def new(lexer) do
    %Monkex.Parser{
      lexer: lexer,
      current_token: nil,
      next_token: nil
    }
    |> next_token
    |> next_token
  end

  @spec next_token(t) :: t
  def next_token(parser) do
    {lex, tok} = Lexer.next_token(parser.lexer)

    %Monkex.Parser{
      lexer: lex,
      current_token: parser.next_token,
      next_token: tok
    }
  end

  @spec current_token_is?(t, atom) :: boolean
  def current_token_is?(parser, type) do
    parser.current_token.type == type
  end

  @spec current_is_eof?(t) :: boolean
  def current_is_eof?(parser) do
    current_token_is?(parser, :eof)
  end

  @spec expect_and_peek(t, atom) :: {:ok, t} | nil
  def expect_and_peek(parser, type) do
    if parser.next_token.type == type do
      {:ok, parser |> next_token}
    else
      nil
    end
  end

  @spec parse_program(t) :: {t, AST.Program.t()}
  def parse_program(parser) do
    parsers_and_statements =
      parser
      |> Stream.unfold(fn p ->
        if current_is_eof?(p) do
          nil
        else
          # parse a statement, then return parser pointed to next token
          case parse_statement(p) do
            {_, nil} -> nil
            {next, stmt} -> {{next |> next_token, stmt}, next |> next_token}
          end
        end
      end)
      |> Enum.to_list()

    statements = parsers_and_statements |> Enum.map(fn {_, stmt} -> stmt end)
    program_parser = parsers_and_statements |> Enum.at(-1) |> elem(0)

    {program_parser, %AST.Program{statements: statements}}
  end

  @spec parse_statement(t) :: {t, AST.Statement.t()} | {t, nil}
  def parse_statement(parser) do
    case parser.current_token.type do
      :let -> parse_let_statement(parser)
      _ -> {parser, nil}
    end
  end

  @spec parse_let_statement(t) :: {t, AST.LetStatement.t()} | {t, nil}
  def parse_let_statement(parser) do
    with {:ok, ident_parser} <- expect_and_peek(parser, :ident),
         {:ok, assign_parser} <- expect_and_peek(ident_parser, :assign) do
      stmt_parser =
        assign_parser
        |> Stream.unfold(fn p ->
          # TODO: parse expressions, but for now, skip until semicolon
          if current_token_is?(p, :semicolon) do
            nil
          else
            next = p |> next_token
            {next, next}
          end
        end)
        # get the last parser
        |> Enum.to_list()
        |> Enum.at(-1)

      {stmt_parser,
       %AST.LetStatement{
         # first parser token
         token: parser.current_token,
         name: %AST.Identifier{
           token: ident_parser.current_token,
           symbol_name: ident_parser.current_token.literal
         },
         value: nil
       }}
    else
      nil -> {parser, nil}
    end
  end
end
