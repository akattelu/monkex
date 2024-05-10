defmodule Monkex.AST.CallExpression do
  alias __MODULE__
  alias Monkex.Object.Node
  alias Monkex.AST.Expression
  alias Monkex.Object.Error
  alias Monkex.Object.Function
  alias Monkex.Environment
  alias Monkex.Object.ReturnValue
  alias Monkex.Object.Builtin

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
    defp args_match(params, args) do
      if length(params) == length(args) do
        :ok
      else
        {:error, "expected #{length(params)} args in function call but was given #{length(args)}"}
      end
    end

    def make_local_env(params, args, fn_env, base_env) do
      Enum.zip(params, args)
      |> Enum.reduce(fn_env, fn {param, arg}, acc ->
        # take result of arg expr
        arg_value = Node.eval(arg, base_env) |> elem(0)

        # TODO: do not assume params are identifiers or handle errors
        Environment.set(acc, param.symbol_name, arg_value)
      end)
    end

    # func can be an idenitifier or a function literal
    def eval(%CallExpression{function: func, arguments: args}, env) do
      case Node.eval(func, env) do
        {%Function{env: fn_env, body: body, params: params}, _} ->
          eval_func(fn_env, body, params, args, env)

        {%Builtin{param_count: param_count, handler: handler}, _} ->
          eval_builtin(param_count, handler, args, env)

        {%Error{}, _} = result ->
          result
      end
    end

    def eval_builtin(param_count, handler, args, base_env) do
      if param_count == length(args) do
        # evaluate the args
        evaluated_args = args |> Enum.map(fn a -> Node.eval(a, base_env) |> elem(0) end)
        {handler.(evaluated_args), base_env}
      else
        {Error.with_message("incorrect number of arguments passed to builtin function"), base_env}
      end
    end

    def eval_func(fn_env, body, params, args, base_env) do
      with :ok <- args_match(params, args),
           local_env <- make_local_env(params, args, fn_env, base_env) do
        case Node.eval(body, local_env) do
          {%ReturnValue{value: value}, _} -> {value, base_env}
          {obj, _} -> {obj, base_env}
        end
      else
        {%Error{}, _} = result ->
          result

        {:error, msg} ->
          {Error.with_message(msg), base_env}
      end
    end
  end
end
