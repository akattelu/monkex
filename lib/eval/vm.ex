defmodule Monkex.VM do
  alias Monkex.Object.Boolean
  alias __MODULE__
  alias Monkex.Instructions
  alias Monkex.Compiler.Bytecode
  alias Monkex.Object.Integer

  defmodule Stack do
    alias __MODULE__

    @moduledoc """
    Custom implementation of the VMs stack
    Uses a backing map instead of a list for constant time operations
    Also does not delete keys of elements that are popped, instead uses a stack pointer to keep track of the top
    """

    @enforce_keys [:store, :sp]
    defstruct [:store, :sp]

    @type t() :: %Stack{}

    @spec new() :: t()
    # start at -1 so pushing points to a valid element
    def new(), do: %Stack{store: %{}, sp: -1}

    @spec top(t()) :: any()
    def top(%Stack{store: store, sp: sp}), do: Map.get(store, sp, nil)

    @spec push(t(), any()) :: t()
    def push(%Stack{store: store, sp: sp}, obj) do
      %Stack{
        store: Map.put(store, sp + 1, obj),
        sp: sp + 1
      }
    end

    @spec pop(t()) :: {t(), any()}
    def pop(%Stack{store: store, sp: sp}) do
      {
        %Stack{store: store, sp: sp - 1},
        Map.get(store, sp, nil)
      }
    end

    @spec last_popped(t()) :: any()
    def last_popped(%Stack{store: store, sp: sp}) do
      Map.get(store, sp + 1, nil)
    end
  end

  @moduledoc """
  VM for running bytecode generated from compiler
  """
  @enforce_keys [:constants, :instructions, :stack]
  defstruct [:constants, :instructions, :stack]

  @type t() :: %VM{}

  defguard is_arithmetic_operator(first) when first >= <<3::8>> and first <= <<6::8>>
  defguard is_comparison_operator(first) when first >= <<9::8>> and first <= <<11::8>>

  @spec operation(<<_::8>>) :: (any(), any() -> any())
  defp operation(<<3::8>>), do: fn a, b -> a + b end
  defp operation(<<4::8>>), do: fn a, b -> a - b end
  defp operation(<<5::8>>), do: fn a, b -> a * b end
  defp operation(<<6::8>>), do: fn a, b -> a / b end
  defp operation(<<9::8>>), do: fn a, b -> a == b end
  defp operation(<<10::8>>), do: fn a, b -> a != b end
  defp operation(<<11::8>>), do: fn a, b -> a > b end

  @spec new(Bytecode.t()) :: t()
  def new(%Bytecode{constants: constants, instructions: instructions}) do
    %VM{
      constants: constants,
      instructions: instructions,
      stack: Stack.new()
    }
  end

  def stack_last_top(%VM{stack: s}), do: Stack.last_popped(s)
  def stack_top(%VM{stack: s}), do: Stack.top(s)

  def run(%VM{instructions: %Instructions{raw: raw}, stack: stack, constants: constants}) do
    {:ok, s, c} = run_raw(raw, stack, constants)

    {:ok,
     %VM{
       stack: s,
       constants: c,
       instructions: <<>>
     }}
  end

  def arithmetic_op(opcode, rest, stack, constants) do
    f = operation(opcode)
    {s, %Integer{value: right}} = Stack.pop(stack)
    {after_pop, %Integer{value: left}} = Stack.pop(s)
    pushed = Stack.push(after_pop, f.(left, right) |> Integer.from())
    run_raw(rest, pushed, constants)
  end

  def type_check(%Integer{}, %Integer{}), do: :ok
  def type_check(%Boolean{}, %Boolean{}), do: :ok
  def type_check(_, _), do: {:error, "type mismatch"}

  def comparison_op(opcode, rest, stack, constants) do
    f = operation(opcode)
    {s, right} = Stack.pop(stack)
    {after_pop, left} = Stack.pop(s)

    with :ok <- type_check(right, left) do
      pushed = Stack.push(after_pop, f.(left, right) |> Boolean.from())
      run_raw(rest, pushed, constants)
    end
  end

  defp run_raw(<<>>, stack, constants), do: {:ok, stack, constants}

  defp run_raw(<<first::binary-size(1)-unit(8), rest::binary>>, stack, constants)
       when is_arithmetic_operator(first),
       do: arithmetic_op(first, rest, stack, constants)

  defp run_raw(<<first::binary-size(1)-unit(8), rest::binary>>, stack, constants)
       when is_comparison_operator(first),
       do: comparison_op(first, rest, stack, constants)

  defp run_raw(<<1::8, rest::binary>>, stack, constants) do
    # constant
    <<int::big-integer-size(2)-unit(8), next::binary>> = rest
    # make this list access faster
    obj = Enum.at(constants, int)
    run_raw(next, Stack.push(stack, obj), constants)
  end

  # push
  defp run_raw(<<2::8, rest::binary>>, stack, constants),
    do: run_raw(rest, Stack.pop(stack) |> elem(0), constants)

  # true
  defp run_raw(<<7::8, rest::binary>>, stack, constants),
    do: run_raw(rest, Stack.push(stack, Boolean.yes()), constants)

  # false
  defp run_raw(<<8::8, rest::binary>>, stack, constants),
    do: run_raw(rest, Stack.push(stack, Boolean.no()), constants)

  # minus
  defp run_raw(<<12::8, rest::binary>>, stack, constants) do
    {s, %Integer{value: value}} = Stack.pop(stack)
    run_raw(rest, Stack.push(s, -value |> Integer.from()), constants)
  end

  # bang
  defp run_raw(<<13::8, rest::binary>>, stack, constants) do
    s =
      case Stack.pop(stack) do
        {s, %Integer{value: value}} ->
          Stack.push(
            s,
            if value == 0 do
              Boolean.yes()
            else
              Boolean.no()
            end
          )

        {s, %Boolean{value: true}} ->
          Stack.push(s, Boolean.no())

        {s, %Boolean{value: false}} ->
          Stack.push(s, Boolean.yes())
      end

    run_raw(rest, s, constants)
  end

  defp run_raw(_, _, _), do: nil
end
