defmodule Monkex.Parser do
  alias Monkex.Lexer
  alias Monkex.AST
  alias Monkex.Parser.Precedence

  @enforce_keys [
    :lexer,
    :current_token,
    :next_token,
    :errors,
    :prefix_parse_fns,
    :infix_parse_fns
  ]
  defstruct [:lexer, :current_token, :next_token, :errors, :prefix_parse_fns, :infix_parse_fns]

  @type t :: %__MODULE__{
          lexer: Monkex.Lexer.t(),
          current_token: Monkex.Token.t() | nil,
          next_token: Monkex.Token.t() | nil,
          errors: list(String.t())
        }

  @spec new(Monkex.Lexer.t()) :: t
  def new(lexer) do
    %Monkex.Parser{
      lexer: lexer,
      current_token: nil,
      next_token: nil,
      errors: [],
      prefix_parse_fns: %{
        :ident => &parse_identifier/1,
        :int => &parse_integer_literal/1,
        :true => &parse_boolean_literal/1,
        :false => &parse_boolean_literal/1,
        :bang => &parse_prefix_expression/1,
        :minus => &parse_prefix_expression/1
      },
      infix_parse_fns: %{
        :plus => &parse_infix_expression/2,
        :minus => &parse_infix_expression/2,
        :slash => &parse_infix_expression/2,
        :asterisk => &parse_infix_expression/2,
        :eq => &parse_infix_expression/2,
        :not_eq => &parse_infix_expression/2,
        :lt => &parse_infix_expression/2,
        :gt => &parse_infix_expression/2
      }
    }
    |> next_token
    |> next_token
  end

  @spec with_error(t, String.t()) :: t
  def with_error(parser, err) do
    %Monkex.Parser{
      parser
      | errors: [err | parser.errors]
    }
  end

  @spec next_token(t) :: t
  def next_token(parser) do
    {lex, tok} = Lexer.next_token(parser.lexer)

    %Monkex.Parser{
      parser
      | lexer: lex,
        current_token: parser.next_token,
        next_token: tok
    }
  end

  @spec current_precedence(t) :: atom
  def current_precedence(parser) do
    parser.current_token.type |> Precedence.of_token()
  end

  @spec next_precedence(t) :: atom
  def next_precedence(parser) do
    parser.next_token.type |> Precedence.of_token()
  end

  @spec current_token_is?(t, atom) :: boolean
  def current_token_is?(parser, type) do
    parser.current_token.type == type
  end

  @spec next_token_is?(t, atom) :: boolean
  def next_token_is?(parser, type) do
    parser.next_token.type == type
  end

  @spec current_is_eof?(t) :: boolean
  def current_is_eof?(parser) do
    current_token_is?(parser, :eof)
  end

  @spec expect_and_peek(t, atom) :: {:ok, t} | {:error, t, String.t()}
  def expect_and_peek(parser, type) do
    if parser.next_token.type == type do
      {:ok, parser |> next_token}
    else
      {:error, parser, "expected #{type}, got #{parser.next_token.type}"}
    end
  end

  defp skip_until_semicolon(parser) do
    parser
    |> Stream.unfold(fn p ->
      if current_token_is?(p, :semicolon) do
        nil
      else
        next = p |> next_token
        {next, next}
      end
    end)
    |> Enum.reverse()
    |> hd
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
            {next, nil} -> {{next |> next_token, nil}, next |> next_token}
            {next, stmt} -> {{next |> next_token, stmt}, next |> next_token}
          end
        end
      end)
      |> Enum.to_list()

    statements =
      parsers_and_statements |> Enum.map(fn {_, stmt} -> stmt end) |> Enum.filter(&(&1 != nil))

    program_parser = parsers_and_statements |> Enum.at(-1) |> elem(0)

    {program_parser, %AST.Program{statements: statements}}
  end

  @spec parse_statement(t) :: {t, AST.Statement.t()} | {t, nil}
  def parse_statement(parser) do
    case parser.current_token.type do
      :let -> parse_let_statement(parser)
      :return -> parse_return_statement(parser)
      _ -> parse_expression_statement(parser)
    end
  end

  @spec parse_return_statement(t) :: {t, AST.ReturnStatement.t()} | {t, nil}
  def parse_return_statement(parser) do
    {parser
     |> next_token
     # TODO: parse expression
     |> skip_until_semicolon(),
     %AST.ReturnStatement{
       token: parser.current_token,
       return_value: nil
     }}
  end

  @spec parse_let_statement(t) :: {t, AST.LetStatement.t()} | {t, nil}
  def parse_let_statement(parser) do
    with {:ok, ident_parser} <- expect_and_peek(parser, :ident),
         {:ok, assign_parser} <- expect_and_peek(ident_parser, :assign) do
      stmt_parser =
        assign_parser
        # TODO: parse expression
        |> skip_until_semicolon

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
      {:error, p, err} -> {p |> with_error(err), nil}
    end
  end

  @spec parse_expression_statement(t) :: {t, AST.ExpressionStatement.t()} | {t, nil}
  def parse_expression_statement(parser) do
    {next, expr} = parse_expression(parser, :lowest)
    # skip semicolon
    final = expect_and_peek(next, :semicolon) |> elem(1)
    {final, %AST.ExpressionStatement{token: parser.current_token, expression: expr}}
  end

  def parse_prefix_expression(parser) do
    {next, expression} =
      parser
      # skip prefix token
      |> next_token
      |> parse_expression(:prefix)

    {next,
     %AST.PrefixExpression{
       token: parser.current_token,
       operator: parser.current_token.literal,
       right: expression
     }}
  end

  def parse_infix_expression(parser, left) do
    {next, right} = parser |> next_token |> parse_expression(parser |> current_precedence)

    {
      next,
      %AST.InfixExpression{
        token: parser.current_token,
        left: left,
        operator: parser.current_token.literal,
        right: right
      }
    }
  end

  def parse_identifier(parser) do
    {parser,
     %AST.Identifier{
       token: parser.current_token,
       symbol_name: parser.current_token.literal
     }}
  end

  def parse_integer_literal(parser) do
    {parser,
     %AST.IntegerLiteral{
       token: parser.current_token,
       value: parser.current_token.literal |> String.to_integer()
     }}
  end
  def parse_boolean_literal(parser) do
    {parser,
     %AST.BooleanLiteral{
       token: parser.current_token,
       value: parser.current_token.literal |> then(fn "true" -> true; "false" -> false end)
     }}
  end

  def parse_expression(parser, precedence) do
    with {:ok, prefix_fn} <- Map.fetch(parser.prefix_parse_fns, parser.current_token.type) do
      {next, left} = prefix_fn.(parser)

      # send in left expression and the last parser pos
      acc =
        prefix_fn.(parser)
        |> Stream.unfold(fn {p, left} ->
          infix_fn = Map.get(p.infix_parse_fns, p.next_token.type)

          cond do
            next_token_is?(p, :semicolon) ->
              nil

            Precedence.compare(precedence, next_precedence(p)) >= 0 ->
              nil

            infix_fn == nil ->
              nil

            true ->
              {next, l} = next |> next_token |> infix_fn.(left)
              {{next, l}, {next, l}}
          end
        end)
        |> Enum.reverse()

      case acc do
        [] -> {next, left}
        [head | _] -> head
      end
    else
      :error -> {parser |> with_error("no prefix function found"), nil}
    end
  end
end
