defmodule Monkex.Parser do
  alias Monkex.AST.ArrayLiteral
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
        :string => &parse_string_literal/1,
        true => &parse_boolean_literal/1,
        false => &parse_boolean_literal/1,
        :bang => &parse_prefix_expression/1,
        :minus => &parse_prefix_expression/1,
        :lparen => &parse_grouped_expression/1,
        :if => &parse_if_expression/1,
        :function => &parse_function_literal/1,
        :lbracket => &parse_array_literal/1
      },
      infix_parse_fns: %{
        :plus => &parse_infix_expression/2,
        :minus => &parse_infix_expression/2,
        :slash => &parse_infix_expression/2,
        :asterisk => &parse_infix_expression/2,
        :eq => &parse_infix_expression/2,
        :not_eq => &parse_infix_expression/2,
        :lt => &parse_infix_expression/2,
        :gt => &parse_infix_expression/2,
        :lparen => &parse_call_expression/2,
        :lbracket => &parse_access_expression/2
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

  @spec skip_optional_semicolon(t) :: t
  defp skip_optional_semicolon(parser) do
    parser |> expect_and_peek(:semicolon) |> elem(1)
  end

  @spec reduce_while(t, any(), (t, any() -> {:halt, t, any()} | {:cont, t, any()})) :: {t, any()}
  def reduce_while(parser, acc, reducer) do
    case reducer.(parser, acc) do
      {:halt, next_parser, next_acc} -> {next_parser, next_acc}
      {:cont, next_parser, next_acc} -> reduce_while(next_parser, next_acc, reducer)
    end
  end

  @spec parse_program(t) :: {t, AST.Program.t()}
  def parse_program(parser) do
    {p, stmts} =
      parser
      |> reduce_while([], fn p, acc ->
        if current_is_eof?(p) do
          {:halt, p, Enum.reverse(acc)}
        else
          # parse a statement, then return parser pointed to next token
          {next, stmt} = parse_statement(p)
          {:cont, next |> next_token, [stmt | acc]}
        end
      end)

    {p, %AST.Program{statements: stmts}}
  end

  @spec parse_statement(t) :: {t, AST.Statement.t()} | {t, nil}
  def parse_statement(parser) do
    case parser.current_token.type do
      :let -> parse_let_statement(parser)
      :return -> parse_return_statement(parser)
      :lbrace -> parse_block_statement(parser)
      _ -> parse_expression_statement(parser)
    end
  end

  @spec parse_return_statement(t) :: {t, AST.ReturnStatement.t()} | {t, nil}
  def parse_return_statement(parser) do
    {next, expr} = parser |> next_token |> parse_expression(:lowest)

    {next |> skip_optional_semicolon,
     %AST.ReturnStatement{
       token: parser.current_token,
       return_value: expr
     }}
  end

  @spec parse_block_statement(t) :: {t, AST.BlockStatement.t()} | {t, nil}
  def parse_block_statement(parser) do
    {final, stmts} =
      parser
      |> next_token
      |> reduce_while([], fn p, acc ->
        if current_token_is?(p, :rbrace) or current_token_is?(p, :eof) do
          {:halt, p, Enum.reverse(acc)}
        else
          {next, stmt} = parse_statement(p)
          {:cont, next |> next_token, [stmt | acc]}
        end
      end)

    {final,
     %AST.BlockStatement{
       token: parser.current_token,
       statements: stmts
     }}
  end

  @spec parse_let_statement(t) :: {t, AST.LetStatement.t()} | {t, nil}
  def parse_let_statement(parser) do
    with {:ok, ident_parser} <- expect_and_peek(parser, :ident),
         {:ok, assign_parser} <- expect_and_peek(ident_parser, :assign) do
      {final, expr} = assign_parser |> next_token |> parse_expression(:lowest)

      {final |> skip_optional_semicolon,
       %AST.LetStatement{
         # first parser token
         token: parser.current_token,
         name: %AST.Identifier{
           token: ident_parser.current_token,
           symbol_name: ident_parser.current_token.literal
         },
         value: expr
       }}
    else
      {:error, p, err} -> {p |> with_error(err), nil}
    end
  end

  @spec parse_expression_statement(t) :: {t, AST.ExpressionStatement.t()} | {t, nil}
  def parse_expression_statement(parser) do
    with {next, expr} <- parse_expression(parser, :lowest) do
      # skip semicolon if it exists, otherwise keep parsing
      {next |> skip_optional_semicolon,
       %AST.ExpressionStatement{token: parser.current_token, expression: expr}}
    end
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
    prec = current_precedence(parser)
    # IO.inspect("Calling infix expression with precedence: #{inspect(prec)}")
    {next, right} = parser |> next_token |> parse_expression(prec)

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

  def parse_call_expression(parser, function) do
    {next, args} = parser |> parse_call_arguments

    {next,
     %AST.CallExpression{
       token: parser.current_token,
       function: function,
       arguments: args
     }}
  end

  def parse_call_arguments(parser), do: parse_expression_list(parser, :rparen)

  def parse_access_expression(parser, indexable) do
    {next, expr} = parser |> next_token |> parse_expression(:lowest)

    case next |> expect_and_peek(:rbracket) do
      {:ok, p} ->
        {p,
         %AST.AccessExpression{
           token: parser.current_token,
           indexable_expr: indexable,
           index_expr: expr
         }}

      {:error, p, msg} ->
        {p |> with_error(msg), nil}
    end
  end

  def parse_grouped_expression(parser) do
    {next, expr} = parser |> next_token |> parse_expression(:lowest)

    case expect_and_peek(next, :rparen) do
      {:ok, p} -> {p, expr}
      {:error, p, err} -> {p |> with_error(err), nil}
    end
  end

  def parse_if_expression(parser) do
    with {:ok, after_if} <- parser |> expect_and_peek(:lparen),
         {after_cond, condition} <- after_if |> next_token |> parse_expression(:lowest),
         {:ok, after_rparen} <- after_cond |> expect_and_peek(:rparen),
         {:ok, at_lb} <- after_rparen |> expect_and_peek(:lbrace),
         {final, then_block} <- at_lb |> parse_block_statement() do
      case final |> expect_and_peek(:else) do
        # no else clause, proceed
        {:error, _, _} ->
          {final,
           %AST.IfExpression{
             token: parser.current_token,
             condition: condition,
             then_block: then_block,
             else_block: nil
           }}

        {:ok, on_else} ->
          case on_else |> expect_and_peek(:lbrace) do
            {:error, p, err} ->
              {p |> with_error(err), nil}

            {:ok, at_else_lb} ->
              {after_else, else_block} = at_else_lb |> parse_block_statement()

              {after_else,
               %AST.IfExpression{
                 token: parser.current_token,
                 condition: condition,
                 then_block: then_block,
                 else_block: else_block
               }}
          end
      end
    else
      {:error, p, err} -> {p |> with_error(err), nil}
    end
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
       value:
         parser.current_token.literal
         |> then(fn
           "true" -> true
           "false" -> false
         end)
     }}
  end

  def parse_string_literal(parser) do
    {parser,
     %AST.StringLiteral{
       token: parser.current_token,
       value: parser.current_token.literal
     }}
  end

  def parse_expression_list(parser, end_token) do
    with false <- next_token_is?(parser, end_token),
         next <- parser |> next_token,
         {after_expr, expr} <- parse_expression(next, :lowest),
         {final, exprs} <-
           after_expr
           |> reduce_while([expr], fn p, acc ->
             if next_token_is?(p, :comma) do
               {after_next, next_expr} =
                 p |> next_token |> next_token |> parse_expression(:lowest)

               {:cont, after_next, [next_expr | acc]}
             else
               {:halt, p, Enum.reverse(acc)}
             end
           end),
         {:ok, p} <- expect_and_peek(final, end_token) do
      {p, exprs}
    else
      true -> {parser |> next_token, []}
      {:error, p, msg} -> {p |> with_error(msg), []}
    end
  end

  def parse_array_literal(parser) do
    {next, items} = parse_expression_list(parser, :rbracket)

    {next,
     %ArrayLiteral{
       token: parser.current_token,
       items: items
     }}
  end

  def parse_function_literal(parser) do
    with {:ok, before_params} <- parser |> expect_and_peek(:lparen),
         {after_params, params} <- before_params |> parse_function_parameters,
         {:ok, before_block} <- after_params |> expect_and_peek(:lbrace),
         {after_block, block} <- before_block |> parse_block_statement do
      {after_block,
       %AST.FunctionLiteral{
         token: parser.current_token,
         params: params,
         body: block
       }}
    else
      {:error, p, err} -> {p |> with_error(err), nil}
    end
  end

  def parse_function_parameters(parser) do
    with false <- next_token_is?(parser, :rparen),
         next <- parser |> next_token,
         {before_ident, ident} <- parse_identifier(next),
         {final, idents} <-
           before_ident
           |> reduce_while([ident], fn p, acc ->
             if next_token_is?(p, :comma) do
               {before_next, next_ident} =
                 p |> next_token |> next_token |> parse_identifier

               {:cont, before_next, [next_ident | acc]}
             else
               {:halt, p, Enum.reverse(acc)}
             end
           end),
         {:ok, p} <- expect_and_peek(final, :rparen) do
      {p, idents}
    else
      true -> {parser |> next_token, []}
      {:error, p, msg} -> {p |> with_error(msg), []}
    end
  end

  def parse_expression(parser, precedence) do
    with {:ok, prefix_fn} <- Map.fetch(parser.prefix_parse_fns, parser.current_token.type) do
      {next, l} = prefix_fn.(parser)
      # send in left expression and the last parser pos
      next
      |> reduce_while(l, fn p, left ->
        infix_fn = Map.get(p.infix_parse_fns, p.next_token.type)

        cond do
          next_token_is?(p, :semicolon) ->
            {:halt, p, left}

          next_token_is?(p, :eof) ->
            {:halt, p, left}

          Precedence.compare(precedence, next_precedence(p)) >= 0 ->
            {:halt, p, left}

          infix_fn == nil ->
            {:halt, p, left}

          true ->
            {next_p, next_l} = p |> next_token |> infix_fn.(left)
            {:cont, next_p, next_l}
        end
      end)
    else
      :error ->
        {parser |> with_error("no prefix function found for #{parser.current_token.literal}"),
         nil}
    end
  end
end
