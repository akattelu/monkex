defmodule Monkex.VM.Stack do
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

defmodule Monkex.VM.InstructionSet do
  alias __MODULE__
  alias Monkex.Instructions

  @moduledoc """
  Wrapper around `Instructions` that preserves the initial set of instructions
  Allows retrieving the head and tail of the instruction set
  Supports moving an instruction pointer for jump opcodes
  """

  @enforce_keys [:ip, :instructions]
  defstruct [:ip, :instructions]

  @type t() :: %InstructionSet{}

  @doc "Create a new instruction set from instructions"
  @spec new(Instructions.t()) :: t()
  def new(%Instructions{} = i) do
    %InstructionSet{
      instructions: i,
      ip: 0
    }
  end

  @doc "Read n_bytes from the instructions at the instruction pointer"
  @spec read(t(), integer()) :: binary()
  def read(%InstructionSet{instructions: %Instructions{raw: raw}, ip: ip}, n_bytes \\ 1) do
    if ip + n_bytes > byte_size(raw) do
      <<>>
    else
      binary_part(raw, ip, n_bytes)
    end
  end

  @doc "Advance the instruction pointer by n bytes"
  @spec advance(t(), integer()) :: t()
  def advance(%InstructionSet{ip: ip} = i, n_bytes \\ 1) do
    %InstructionSet{
      i
      | ip: ip + n_bytes
    }
  end

  @doc "Advance the instruction pointer to pos"
  @spec jump(t(), integer()) :: t()
  def jump(set, pos) do
    %InstructionSet{
      set
      | ip: pos
    }
  end
end

defmodule Monkex.VM do
  alias __MODULE__
  alias Monkex.Object.Boolean
  alias Monkex.Object.Integer
  alias Monkex.Object.Null
  alias Monkex.Compiler.Bytecode
  alias Monkex.VM.Stack
  alias Monkex.VM.InstructionSet

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
      instructions: InstructionSet.new(instructions),
      stack: Stack.new()
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

    # make this list access faster
    obj = Enum.at(constants, int)

    vm |> advance(3) |> with_stack(Stack.push(stack, obj)) |> run
  end

  # Pop
  defp run_op(<<2::8>>, %VM{stack: stack} = vm),
    do: vm |> advance() |> with_stack(Stack.pop(stack) |> elem(0)) |> run

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

  defp run_op(<<>>, vm), do: {:ok, vm}
  defp run_op(_, _), do: {:error, "unknown opcode"}
end
