defmodule Monkex.VM do
  alias __MODULE__

  alias Monkex.Object.{
    Boolean,
    Integer,
    Array,
    Null
  }

  alias Monkex.Object.String, as: StringObj
  alias Monkex.Compiler.Bytecode
  alias Monkex.VM.Stack
  alias Monkex.VM.InstructionSet
  alias Monkex.VM.ArrayList

  @moduledoc """
  VM for running bytecode generated from compiler
  """
  @enforce_keys [:constants, :instructions, :stack, :globals]
  defstruct [:constants, :instructions, :stack, :globals]

  @type t() :: %VM{}

  defguard is_arithmetic_operator(first) when first >= <<4::8>> and first <= <<6::8>>
  defguard is_comparison_operator(first) when first >= <<9::8>> and first <= <<11::8>>

  @spec operation(<<_::8>>) :: (any(), any() -> any())
  defp operation(<<4::8>>), do: fn a, b -> a - b end
  defp operation(<<5::8>>), do: fn a, b -> a * b end
  defp operation(<<6::8>>), do: fn a, b -> a / b end
  defp operation(<<9::8>>), do: fn a, b -> a == b end
  defp operation(<<10::8>>), do: fn a, b -> a != b end
  defp operation(<<11::8>>), do: fn a, b -> a > b end

  @spec new(Bytecode.t()) :: t()
  def new(%Bytecode{constants: constants, instructions: instructions}) do
    %VM{
      constants: ArrayList.new(constants),
      instructions: InstructionSet.new(instructions),
      stack: Stack.new(),
      globals: ArrayList.new()
    }
  end

  @doc "Return the VM with instruction pointer incremented by n_bytes"
  @spec advance(t(), integer()) :: t()
  def advance(%VM{instructions: iset} = vm, n_bytes \\ 1) do
    %VM{
      vm
      | instructions: iset |> InstructionSet.advance(n_bytes)
    }
  end

  @doc "Return the VM with instruction pointer incremented by n_bytes"
  @spec with_stack(t(), Stack.t()) :: t()
  def with_stack(%VM{} = vm, stack) do
    %VM{
      vm
      | stack: stack
    }
  end

  @doc "Return the VM with the set of globals updated"
  @spec with_globals(t(), ArrayList.t()) :: t()
  def with_globals(%VM{} = vm, globals) do
    %VM{
      vm
      | globals: globals
    }
  end

  @doc "Return the VM with instruction pointer jumped to the position"
  @spec jump(t(), integer()) :: t()
  def jump(%VM{instructions: iset} = vm, pos) do
    %VM{
      vm
      | instructions: iset |> InstructionSet.jump(pos)
    }
  end

  def stack_last_top(%VM{stack: s}), do: Stack.last_popped(s)
  def stack_top(%VM{stack: s}), do: Stack.top(s)

  def type_check(%Integer{}, %Integer{}), do: :ok
  def type_check(%Boolean{}, %Boolean{}), do: :ok
  def type_check(%StringObj{}, %StringObj{}), do: :ok
  def type_check(_, _), do: {:error, "type mismatch"}

  @doc "Execute all instructions in the VM"
  def run(%VM{instructions: iset} = vm) do
    opcode = InstructionSet.read(iset)
    run_op(opcode, vm)
  end

  # Arithmetic
  defp run_op(first, %VM{stack: stack} = vm)
       when is_arithmetic_operator(first) do
    f = operation(first)
    {s, %Integer{value: right}} = Stack.pop(stack)
    {after_pop, %Integer{value: left}} = Stack.pop(s)
    pushed = Stack.push(after_pop, f.(left, right) |> Integer.from())
    vm |> advance() |> with_stack(pushed) |> run
  end

  # Comparison
  defp run_op(first, %VM{stack: stack} = vm)
       when is_comparison_operator(first) do
    f = operation(first)
    {s, right} = Stack.pop(stack)
    {after_pop, left} = Stack.pop(s)

    with :ok <- type_check(right, left) do
      pushed = Stack.push(after_pop, f.(left, right) |> Boolean.from())
      vm |> advance() |> with_stack(pushed) |> run
    end
  end

  # Constant
  defp run_op(<<1::8>>, %VM{instructions: iset, stack: stack, constants: constants} = vm) do
    <<int::big-integer-size(2)-unit(8), _::binary>> =
      iset |> InstructionSet.advance() |> InstructionSet.read(2)

    {:ok, obj} = ArrayList.at(constants, int)

    vm |> advance(3) |> with_stack(Stack.push(stack, obj)) |> run
  end

  # Pop
  defp run_op(<<2::8>>, %VM{stack: stack} = vm),
    do: vm |> advance() |> with_stack(Stack.pop(stack) |> elem(0)) |> run

  # Add / concatenate
  defp run_op(<<3::8>>, %VM{stack: stack} = vm) do
    {s, right} = Stack.pop(stack)
    {s, left} = Stack.pop(s)

    with :ok <- type_check(left, right) do
      result_obj =
        case {left, right} do
          {%Integer{value: l}, %Integer{value: r}} -> (l + r) |> Integer.from()
          {%StringObj{value: l}, %StringObj{value: r}} -> (l <> r) |> StringObj.from()
        end

      s = Stack.push(s, result_obj)

      vm |> advance() |> with_stack(s) |> run
    end
  end

  # True
  defp run_op(<<7::8>>, %VM{stack: stack} = vm),
    do: vm |> advance() |> with_stack(Stack.push(stack, Boolean.yes())) |> run

  # False
  defp run_op(<<8::8>>, %VM{stack: stack} = vm),
    do: vm |> advance() |> with_stack(Stack.push(stack, Boolean.no())) |> run

  # Minus
  defp run_op(<<12::8>>, %VM{stack: stack} = vm) do
    {s, %Integer{value: value}} = Stack.pop(stack)
    pushed = Stack.push(s, -value |> Integer.from())

    vm |> advance() |> with_stack(pushed) |> run
  end

  # Bang
  defp run_op(<<13::8>>, %VM{stack: stack} = vm) do
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

        {s, %Null{}} ->
          Stack.push(s, Boolean.yes())
      end

    vm |> advance() |> with_stack(s) |> run
  end

  # Jump not truthy
  defp run_op(<<14::8>>, %VM{stack: stack, instructions: iset} = vm) do
    {s, should_not_jump_val} = Stack.pop(stack)

    <<jump_pos::big-integer-size(2)-unit(8), _::binary>> =
      iset |> InstructionSet.advance() |> InstructionSet.read(2)

    case should_not_jump_val do
      # do jump
      %Boolean{value: false} -> vm |> with_stack(s) |> jump(jump_pos)
      %Integer{value: 0} -> vm |> with_stack(s) |> jump(jump_pos)
      %Null{} -> vm |> with_stack(s) |> jump(jump_pos)
      # do not jump
      %Boolean{value: true} -> vm |> advance(3) |> with_stack(s)
      %Integer{value: _} -> vm |> advance(3) |> with_stack(s)
    end
    |> run
  end

  # Jump unconditionally
  defp run_op(<<15::8>>, %VM{instructions: iset} = vm) do
    <<jump_pos::big-integer-size(2)-unit(8), _::binary>> =
      iset |> InstructionSet.advance() |> InstructionSet.read(2)

    vm |> jump(jump_pos) |> run
  end

  # Null
  defp run_op(<<16::8>>, %VM{stack: stack} = vm) do
    vm |> advance() |> with_stack(Stack.push(stack, Null.object())) |> run
  end

  # Set global
  defp run_op(<<17::8>>, %VM{instructions: iset, stack: stack, globals: globals} = vm) do
    <<global_idx::big-integer-size(2)-unit(8), _::binary>> =
      iset |> InstructionSet.advance() |> InstructionSet.read(2)

    {s, obj} = Stack.pop(stack)
    new_globals = ArrayList.set(globals, global_idx, obj)
    vm |> advance(3) |> with_stack(s) |> with_globals(new_globals) |> run
  end

  # Get global
  defp run_op(<<18::8>>, %VM{instructions: iset, stack: stack, globals: globals} = vm) do
    <<global_idx::big-integer-size(2)-unit(8), _::binary>> =
      iset |> InstructionSet.advance() |> InstructionSet.read(2)

    {:ok, obj} = ArrayList.at(globals, global_idx)
    s = Stack.push(stack, obj)
    vm |> advance(3) |> with_stack(s) |> run
  end

  # Array
  defp run_op(<<19::8>>, %VM{instructions: iset, stack: stack} = vm) do
    <<array_items::big-integer-size(2)-unit(8), _::binary>> =
      iset |> InstructionSet.advance() |> InstructionSet.read(2)

    {s, items} = Stack.take(stack, array_items)
    array_obj = Array.from(items)
    s = Stack.push(s, array_obj)

    vm |> advance(3) |> with_stack(s) |> run
  end

  defp run_op(<<>>, vm), do: {:ok, vm}
  defp run_op(_, _), do: {:error, "unknown opcode"}
end
