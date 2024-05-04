defmodule Monkex.AST.CallExpression do
  alias __MODULE__
  alias Monkex.Object.Node
  alias Monkex.AST.Expression
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
    alias Monkex.Object.ReturnValue

    defp args_match(params, args) do
      if length(params) == length(args) do
        :ok
      else
        {:error,
         "expected #{length(params)} args in function call but was given #{length(args)}"}
      end
    end

    def eval(%CallExpression{function: func, arguments: args}, env) do
      # resolve the fn object if its an identifier or a literal
      with {%Function{env: fn_env, body: body, params: params}, env} <- Node.eval(func, env),
           :ok <- args_match(params, args) do
        local_env =
          Enum.zip(params, args)
          |> Enum.reduce(fn_env, fn {param, arg}, acc ->
            # take result of arg expr
            arg_value = Node.eval(arg, env) |> elem(0)

            # TODO: do not assume params are identifiers or handle errors
            Environment.set(acc, param.symbol_name, arg_value)
          end)

        case Node.eval(body, local_env) do
          {%ReturnValue{value: value}, _} -> {value, env}
          {obj, _} -> {obj, env}
        end
      else
        {%Error{}, _} = result -> result

        {:error, msg} ->
          {Error.with_message(msg), env}
      end
    end
  end
end
