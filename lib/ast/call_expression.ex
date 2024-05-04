defmodule Monkex.AST.CallExpression do
  alias __MODULE__
  alias Monkex.Object.Node
  alias Monkex.AST.Expression
  alias Monkex.AST.Identifier
  alias Monkex.Object.Error
  alias Monkex.Object.Function
  alias Monkex.Environment

  @enforce_keys [:token, :function, :arguments]
  defstruct [:token, :function, :arguments]

  defimpl Expression, for: CallExpression do
    def token_literal(%CallExpression{token: token}), do: token.literal
  end

  defimpl String.Chars, for: CallExpression do
    def to_string(%CallExpression{
          token: token,
          function: function,
          arguments: arguments
        }),
        do: "#{function}#{token.literal}#{Enum.join(arguments, ", ")})"
  end

  defimpl Node, for: CallExpression do
    alias Monkex.AST.FunctionLiteral

    defp args_match(fn_name, params, args) do
      if length(params) == length(args) do
        :ok
      else
        {:error,
         "expected #{length(params)} args in call to #{fn_name} but was only given #{length(args)}"}
      end
    end

    def eval(%CallExpression{function: %Identifier{symbol_name: fn_name}, arguments: args}, env) do
      with {:ok, %Function{body: body, params: params, env: _}} <- Environment.get(env, fn_name),
           :ok <- args_match(fn_name, params, args) do
        local_env =
          Enum.zip(params, args)
          |> Enum.reduce(env, fn {param, arg}, acc ->
            # take result of arg expr
            arg_value = Node.eval(arg, env) |> elem(0)

            # TODO: do not assume params are identifiers or handle errors
            Environment.set(acc, param.symbol_name, arg_value)
          end)

        Node.eval(body, local_env)
      else
        :undefined ->
          {Error.with_message("attempted to call undefined function: #{fn_name}"), env}

        {:error, msg} ->
          {Error.with_message(msg), env}
      end
    end

    def eval(
          %CallExpression{
            function: %FunctionLiteral{params: params, body: body},
            arguments: args
          },
          env
        ) do
      with :ok <- args_match("anonymous", params, args) do
        local_env =
          Enum.zip(params, args)
          |> Enum.reduce(env, fn {param, arg}, acc ->
            # take result of arg expr
            arg_value = Node.eval(arg, env) |> elem(0)

            # TODO: do not assume params are identifiers or handle errors
            Environment.set(acc, param.symbol_name, arg_value)
          end)

        Node.eval(body, local_env)
      else
        {:error, msg} ->
          {Error.with_message(msg), env}
      end
    end
  end
end
