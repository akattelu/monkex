defmodule Monkex.VM do
  alias __MODULE__

  alias Monkex.Object.{
    Boolean,
    Integer,
    Array,
    Null,
    Dictionary,
    CompiledFunction,
    Builtin,
    Closure
  }

  alias Monkex.Object.String, as: StringObj
  alias Monkex.Compiler.Bytecode
  alias Monkex.Container.{ArrayList, Stack}
  alias Monkex.VM.InstructionSet

  @moduledoc """
  VM for running bytecode generated from compiler
  """
  @enforce_keys [:constants, :stack, :globals, :frames]
  defstruct [:constants, :stack, :globals, :frames]

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
      stack: Stack.new(),
      globals: ArrayList.new(),
      frames: Stack.new() |> Stack.push(InstructionSet.new(instructions))
    }
  end

  @doc "Return a new VM with the frame on the top of the stack replaced"
  @spec replace_top_frame(t(), InstructionSet.t()) :: t()
  def replace_top_frame(%VM{frames: frames} = vm, iset) do
    {f, _} = Stack.pop(frames)
    new_frames = Stack.push(f, iset)

    %VM{
      vm
      | frames: new_frames
    }
  end

  @doc "Retrieve the instructions associated with the top stack frame"
  @spec instructions(t()) :: InstructionSet.t()
  def instructions(%VM{frames: frames}) do
    frames |> Stack.top()
  end

  @doc "Return the VM with instruction pointer incremented by n_bytes"
  @spec advance(t(), integer()) :: t()
  def advance(%VM{frames: frames} = vm, n_bytes \\ 1) do
    frame =
      frames
      |> Stack.top()
      |> InstructionSet.advance(n_bytes)

    vm |> replace_top_frame(frame)
  end

  @doc "Return the VM with instruction pointer incremented by n_bytes"
  @spec with_stack(t(), Stack.t()) :: t()
  def with_stack(%VM{} = vm, stack) do
    %VM{
      vm
      | stack: stack
    }
  end

  @doc "Return the VM with the stack frames updated"
  @spec with_frames(t(), Stack.t()) :: t()
  def with_frames(vm, frames) do
    %VM{vm | frames: frames}
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
  def jump(%VM{} = vm, pos) do
    frame = vm |> instructions |> InstructionSet.jump(pos)
    vm |> replace_top_frame(frame)
  end

  def stack_last_top(%VM{stack: s}), do: Stack.last_popped(s)
  def stack_top(%VM{stack: s}), do: Stack.top(s)

  defp type_check(%Integer{}, %Integer{}), do: :ok
  defp type_check(%Boolean{}, %Boolean{}), do: :ok
  defp type_check(%StringObj{}, %StringObj{}), do: :ok
  defp type_check(_, _), do: {:error, "type mismatch"}

  @doc "Execute all instructions in the VM"
  def run(%VM{} = vm) do
    iset = vm |> instructions
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
  defp run_op(<<1::8>>, %VM{stack: stack, constants: constants} = vm) do
    iset = vm |> instructions

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
  defp run_op(<<14::8>>, %VM{stack: stack} = vm) do
    iset = vm |> instructions
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
  defp run_op(<<15::8>>, %VM{} = vm) do
    iset = vm |> instructions

    <<jump_pos::big-integer-size(2)-unit(8), _::binary>> =
      iset |> InstructionSet.advance() |> InstructionSet.read(2)

    vm |> jump(jump_pos) |> run
  end

  # Null
  defp run_op(<<16::8>>, %VM{stack: stack} = vm) do
    vm |> advance() |> with_stack(Stack.push(stack, Null.object())) |> run
  end

  # Set global
  defp run_op(<<17::8>>, %VM{stack: stack, globals: globals} = vm) do
    iset = vm |> instructions

    <<global_idx::big-integer-size(2)-unit(8), _::binary>> =
      iset |> InstructionSet.advance() |> InstructionSet.read(2)

    {s, obj} = Stack.pop(stack)
    new_globals = ArrayList.set(globals, global_idx, obj)
    vm |> advance(3) |> with_stack(s) |> with_globals(new_globals) |> run
  end

  # Get global
  defp run_op(<<18::8>>, %VM{stack: stack, globals: globals} = vm) do
    iset = vm |> instructions

    <<global_idx::big-integer-size(2)-unit(8), _::binary>> =
      iset |> InstructionSet.advance() |> InstructionSet.read(2)

    {:ok, obj} = ArrayList.at(globals, global_idx)
    s = Stack.push(stack, obj)
    vm |> advance(3) |> with_stack(s) |> run
  end

  # Array
  defp run_op(<<19::8>>, %VM{stack: stack} = vm) do
    iset = vm |> instructions

    <<array_items::big-integer-size(2)-unit(8), _::binary>> =
      iset |> InstructionSet.advance() |> InstructionSet.read(2)

    {s, items} = Stack.take(stack, array_items)
    array_obj = Array.from(items)
    s = Stack.push(s, array_obj)

    vm |> advance(3) |> with_stack(s) |> run
  end

  # Hash
  defp run_op(<<20::8>>, %VM{stack: stack} = vm) do
    iset = vm |> instructions

    <<hash_items::big-integer-size(2)-unit(8), _::binary>> =
      iset |> InstructionSet.advance() |> InstructionSet.read(2)

    {s, items} = Stack.take(stack, hash_items)

    dict_obj =
      items
      |> Enum.chunk_every(2)
      |> Enum.reduce(%{}, fn [k | [v | []]], acc_map ->
        Map.put(acc_map, k, v)
      end)
      |> Dictionary.from()

    s = Stack.push(s, dict_obj)

    vm |> advance(3) |> with_stack(s) |> run
  end

  # Access/index 
  defp run_op(<<21::8>>, %VM{stack: stack} = vm) do
    {s, [indexable | [index | []]]} = Stack.take(stack, 2)

    obj =
      with {%Array{} = arr, %Integer{value: v}} <- {indexable, index},
           {:ok, obj} <- Array.at(arr, v) do
        obj
      else
        {%Dictionary{} = dict, v} ->
          Dictionary.at(dict, v)

        {:error, "index out of bounds"} ->
          Null.object()
      end

    s = Stack.push(s, obj)

    vm |> advance() |> with_stack(s) |> run
  end

  # Call
  defp run_op(<<22::8>>, %VM{stack: stack} = vm) do
    <<num_args::big-integer-size(1)-unit(8), _::binary>> =
      vm |> instructions |> InstructionSet.advance() |> InstructionSet.read(1)

    case Stack.at(stack, Stack.sp(stack) - num_args) do
      %Closure{
        func: %CompiledFunction{
          instructions: instructions,
          num_locals: num_locals,
          num_params: num_params
        },
        free_objects: objects
      } ->
        call_function(vm, instructions, stack, num_args, num_params, num_locals, objects)

      %Builtin{
        param_count: num_params,
        handler: handler
      } ->
        call_builtin(vm, stack, handler, num_args, num_params)

      _ ->
        {:error, "using call on a non-function or non-builtin"}
    end
  end

  # Return value
  defp run_op(<<23::8>>, %VM{stack: stack, frames: frames} = vm) do
    {s, ret_val} = Stack.pop(stack)
    {new_frames, %InstructionSet{base_pointer: bp}} = Stack.pop(frames)
    {s, _} = s |> Stack.set_pointer(bp) |> Stack.pop()
    new_stack = s |> Stack.push(ret_val)
    vm |> with_frames(new_frames) |> advance() |> with_stack(new_stack) |> run
  end

  # Return
  defp run_op(<<24::8>>, %VM{frames: frames, stack: stack} = vm) do
    {new_frames, %InstructionSet{base_pointer: bp}} = Stack.pop(frames)
    {s, _} = stack |> Stack.set_pointer(bp) |> Stack.pop()
    new_stack = s |> Stack.push(Null.object())
    vm |> with_frames(new_frames) |> advance() |> with_stack(new_stack) |> run
  end

  # Set local
  defp run_op(<<25::8>>, %VM{stack: stack} = vm) do
    %InstructionSet{base_pointer: bp} = iset = vm |> instructions

    <<local_idx::big-integer-size(1)-unit(8), _::binary>> =
      iset |> InstructionSet.advance() |> InstructionSet.read(1)

    {s, obj} = Stack.pop(stack)
    with_local_set = Stack.set(s, bp + local_idx + 1, obj)

    vm |> with_stack(with_local_set) |> advance(2) |> run
  end

  # Get local
  defp run_op(<<26::8>>, %VM{frames: frames, stack: stack} = vm) do
    iset = vm |> instructions

    <<local_idx::big-integer-size(1)-unit(8), _::binary>> =
      iset |> InstructionSet.advance() |> InstructionSet.read(1)

    %InstructionSet{base_pointer: bp} = Stack.top(frames)

    obj = Stack.at(stack, bp + local_idx + 1)
    s = Stack.push(stack, obj)
    vm |> with_stack(s) |> advance(2) |> run
  end

  # Get builtin
  defp run_op(<<27::8>>, %VM{stack: stack} = vm) do
    <<builtin_idx::big-integer-size(1)-unit(8), _::binary>> =
      vm |> instructions |> InstructionSet.advance() |> InstructionSet.read(1)

    {_, builtin} = Builtin.all() |> Enum.at(builtin_idx)
    with_builtin = Stack.push(stack, builtin)

    vm |> with_stack(with_builtin) |> advance(2) |> run
  end

  # Closure
  defp run_op(<<28::8>>, %VM{stack: stack, constants: constants} = vm) do
    iset = vm |> instructions |> InstructionSet.advance()

    <<constant_idx::big-integer-size(2)-unit(8), _::binary>> =
      iset |> InstructionSet.read(2)

    <<free_variables::big-integer-size(1)-unit(8), _::binary>> =
      iset |> InstructionSet.advance(2) |> InstructionSet.read(1)

    {stack, objs} = Stack.take(stack, free_variables)

    case ArrayList.at(constants, constant_idx) do
      {:ok, %CompiledFunction{} = cf} ->
        vm |> advance(4) |> with_stack(Stack.push(stack, Closure.from(cf, objs))) |> run

      _ ->
        {:error, "not a function"}
    end
  end

  # Get free 
  defp run_op(<<29::8>>, %VM{stack: stack, frames: frames} = vm) do
    <<free_idx::big-integer-size(1)-unit(8), _::binary>> =
      vm |> instructions |> InstructionSet.advance() |> InstructionSet.read(1)

    %InstructionSet{closure: %Closure{free_objects: objects}} = Stack.top(frames)

    obj = Enum.at(objects, free_idx)

    stack = Stack.push(stack, obj)

    vm |> advance(2) |> with_stack(stack) |> run
  end

  # Current closure
  defp run_op(<<30::8>>, %VM{stack: stack, frames: frames} = vm) do
    %InstructionSet{closure: closure} = Stack.top(frames)
    stack = Stack.push(stack, closure)
    vm |> advance() |> with_stack(stack) |> run
  end

  defp run_op(<<>>, vm), do: {:ok, vm}
  defp run_op(_, _), do: {:error, "unknown opcode"}

  defp call_function(vm, instructions, stack, num_args, num_params, num_locals, objects) do
    if num_params != num_args do
      {:error, "wrong number of arguments, expected: #{num_params}, got: #{num_args}"}
    else
      # advance past the num_args before pushing stack frame
      %VM{frames: after_skip_arg_instr} = vm |> advance

      frames =
        Stack.push(
          after_skip_arg_instr,
          InstructionSet.new(
            instructions,
            Stack.sp(stack) - num_args,
            objects,
            num_locals,
            num_params
          )
        )

      next_stack = Stack.make_space(stack, num_locals)
      vm |> with_stack(next_stack) |> with_frames(frames) |> run
    end
  end

  defp call_builtin(vm, stack, handler, num_args, num_params) do
    if num_params != num_args do
      {:error, "wrong number of arguments, expected: #{num_params}, got: #{num_args}"}
    else
      {s, args} = Stack.take(stack, num_args)

      case handler.(args) do
        {:error, msg} ->
          {:error, msg}

        result_obj ->
          s = Stack.push(s, result_obj)
          vm |> advance(2) |> with_stack(s) |> run()
      end
    end
  end
end
