defprotocol Monkex.Object do
  # Type of the object
  def type(obj)
end

defprotocol Monkex.Object.Node do
  def eval(node, env)

  @spec compile(Monkex.Object.Node, Monkex.Compiler.t()) ::
          {:ok, Monkex.Compiler.t()} | {:error, String.t()}
  @fallback_to_any true
  def compile(node, compiler)
end

defimpl Monkex.Object.Node, for: Any do
  def eval(_node, _env), do: raise("not implemented")
  def compile(_node, _compiler), do: raise("not implemented")
end

defmodule Monkex.Object.Integer do
  @moduledoc "Internal object representation for an integer"
  alias __MODULE__
  @enforce_keys [:value]
  defstruct [:value]

  def from(value), do: %Integer{value: value}

  defimpl Monkex.Object, for: Integer do
    def type(_), do: :integer
  end

  defimpl String.Chars, for: Integer do
    def to_string(obj), do: "#{obj.value}"
  end
end

defmodule Monkex.Object.Boolean do
  @moduledoc "Internal object representation for a boolean"
  alias __MODULE__
  @enforce_keys [:value]
  defstruct [:value]

  def yes(), do: %Boolean{value: true}
  def no(), do: %Boolean{value: false}
  def from(true), do: yes()
  def from(false), do: no()

  defimpl Monkex.Object, for: Boolean do
    def type(_), do: :boolean
  end

  defimpl String.Chars, for: Boolean do
    def to_string(obj), do: "#{obj.value}"
  end
end

defmodule Monkex.Object.Null do
  @moduledoc "Internal object representation for NULL"
  alias __MODULE__
  defstruct []

  def object() do
    %Null{}
  end

  defimpl Monkex.Object, for: Null do
    def type(_), do: :null
  end

  defimpl String.Chars, for: Null do
    def to_string(_), do: "NULL"
  end
end

defmodule Monkex.Object.ReturnValue do
  @moduledoc "Internal object representation for a return value that needs to be propagated up"
  alias __MODULE__

  @enforce_keys [:value]
  defstruct [:value]

  def from(%ReturnValue{} = x) do
    x
  end

  def from(obj), do: %ReturnValue{value: obj}

  defimpl Monkex.Object, for: ReturnValue do
    def type(_), do: :return_value
  end

  defimpl String.Chars, for: ReturnValue do
    def to_string(_), do: "ReturnValue"
  end
end

defmodule Monkex.Object.Error do
  @moduledoc "Internal object representation for an interpreter error"
  alias __MODULE__

  @enforce_keys [:message]
  defstruct [:message]

  def with_message(msg), do: %Error{message: msg}

  defimpl Monkex.Object, for: Error do
    def type(_), do: :error
  end

  defimpl String.Chars, for: Error do
    def to_string(%Error{message: msg}), do: "Error: #{msg}"
  end
end

defmodule Monkex.Object.Function do
  @moduledoc "Internal object representation for a function"
  alias __MODULE__

  @enforce_keys [:params, :body, :env]
  defstruct [:params, :body, :env]

  def new(params, body, env) do
    %Function{
      params: params,
      body: body,
      env: env
    }
  end

  defimpl Monkex.Object, for: Function do
    def type(_), do: :function
  end

  defimpl String.Chars, for: Function do
    def to_string(%Function{params: params, body: body}),
      do: "fn(#{Enum.join(params, ", ")}) #{body}"
  end
end

defmodule Monkex.Object.String do
  @moduledoc "Internal object representation for a string"
  alias __MODULE__, as: ObjString
  @enforce_keys [:value]
  defstruct [:value]

  def from(value), do: %ObjString{value: value}

  defimpl Monkex.Object, for: ObjString do
    def type(_), do: :string
  end

  defimpl String.Chars, for: ObjString do
    def to_string(%ObjString{value: value}), do: "\"#{value}\""
  end
end

defmodule Monkex.Object.Array do
  @moduledoc "Internal object representation for an array"
  alias __MODULE__
  alias Monkex.Object.Null
  @enforce_keys [:items]
  defstruct [:items]

  def from(items) do
    %Array{
      items: items
    }
  end

  def at(%Array{items: items}, index) do
    if index >= length(items) or index < 0 do
      {:error, "index out of bounds"}
    else
      {:ok, Enum.at(items, index, Null.object())}
    end
  end

  def push(%Array{items: items}, obj), do: (items ++ [obj]) |> Array.from()
  def head(%Array{items: [h | _]}), do: h
  def head(%Array{items: []}), do: Null.object()
  def tail(%Array{items: []}), do: Null.object()
  def tail(%Array{items: [_ | t]}), do: Array.from(t)
  def last(%Array{items: []}), do: Null.object()
  def last(%Array{items: items}), do: List.last(items)
  def cons(%Array{items: items}, item), do: [item | items] |> Array.from()

  defimpl Monkex.Object, for: Array do
    def type(_), do: :array
  end

  defimpl String.Chars, for: Array do
    def to_string(%Array{items: items}), do: "[#{Enum.join(items, ", ")}]"
  end
end

defmodule Monkex.Object.Dictionary do
  @moduledoc "Internal object representation for a dictionary"
  alias __MODULE__
  alias Monkex.Object.Null
  @enforce_keys [:map]
  defstruct [:map]

  def from(map), do: %Dictionary{map: map}

  def at(%Dictionary{map: map}, index) do
    Map.get(map, index, Null.object())
  end

  defimpl Monkex.Object, for: Dictionary do
    def type(_), do: :dict
  end

  defimpl String.Chars, for: Dictionary do
    def to_string(%Dictionary{map: map}) do
      pairs =
        map
        |> Map.to_list()
        |> Enum.map(fn {k, v} ->
          "#{k}: #{v}"
        end)

      "{#{Enum.join(pairs, ", ")}}"
    end
  end
end

defmodule Monkex.Object.Builtin do
  @moduledoc "Internal object representation for a builtin function implemented in elixir"
  alias __MODULE__
  alias Monkex.Object
  alias Monkex.Object.Array
  alias Monkex.Object.Integer
  alias Monkex.Object.String, as: StringObj
  alias Monkex.Object.Null
  alias Monkex.Object.Error
  defstruct [:param_count, :handler]

  @type t() :: %Builtin{}

  def all() do
    [
      {"len", %Builtin{param_count: 1, handler: &Builtin.len/1}},
      {"head", %Builtin{param_count: 1, handler: &Builtin.head/1}},
      {"tail", %Builtin{param_count: 1, handler: &Builtin.tail/1}},
      {"last", %Builtin{param_count: 1, handler: &Builtin.last/1}},
      {"puts", %Builtin{param_count: 1, handler: &Builtin.puts/1}},
      {"charAt", %Builtin{param_count: 2, handler: &Builtin.char_at/1}},
      {"cons", %Builtin{param_count: 2, handler: &Builtin.cons/1}},
      {"push", %Builtin{param_count: 2, handler: &Builtin.push/1}},
      {"parseInt", %Builtin{param_count: 1, handler: &Builtin.parse_int/1}},
      {"read", %Builtin{param_count: 1, handler: &Builtin.read/1}},
      {"readLines", %Builtin{param_count: 1, handler: &Builtin.read_lines/1}}
    ]
  end

  def find(ident) do
    Enum.find(all(), nil, fn {name, _} -> ident == name end)
  end

  def read([%StringObj{value: path} | _]) do
    case File.read(path) do
      {:ok, data} -> StringObj.from(data)
      {:error, _} -> Error.with_message("could not read file #{path}")
    end
  end

  def read_lines([%StringObj{value: path} | _]) do
    case File.read(path) do
      {:ok, data} -> data |> String.split("\n") |> Enum.map(&StringObj.from/1) |> Array.from()
      {:error, _} -> Error.with_message("could not read file #{path}")
    end
  end

  def puts([obj | _]) do
    IO.puts("#{obj}")
    Null.object()
  end

  def parse_int([%StringObj{value: value} | _]),
    do: value |> String.to_integer() |> Integer.from()

  def len([%StringObj{value: value} | []]), do: String.length(value) |> Integer.from()
  def len([%Array{items: items} | []]), do: length(items) |> Integer.from()
  def len([obj | []]), do: {:error, "argument to `len` not supported, got #{Object.type(obj)}"}
  def len(arr), do: {:error, "wrong number of arguments, expected: 1, got: #{length(arr)}"}

  def char_at([%StringObj{value: str} | [%Integer{value: int} | _]]),
    do: str |> String.at(int) |> String.Chars.to_string() |> StringObj.from()

  def push([%Array{} = arr | [val | _]]), do: Array.push(arr, val)

  def push([obj | [_ | _]]),
    do: {:error, "argument to `push` must be array, got #{Object.type(obj)}"}

  def head([%Array{} = arr | _]), do: Array.head(arr)
  def head([obj | _]), do: {:error, "argument to `head` must be array, got #{Object.type(obj)}"}
  def tail([%Array{} = arr | _]), do: Array.tail(arr)
  def tail([obj | _]), do: {:error, "argument to `tail` must be array, got #{Object.type(obj)}"}
  def last([%Array{} = arr | _]), do: Array.last(arr)
  def last([obj | _]), do: {:error, "argument to `last` must be array, got #{Object.type(obj)}"}
  def cons([%Array{} = arr | [obj | _]]), do: Array.cons(arr, obj)
end

defmodule Monkex.Object.CompiledFunction do
  @moduledoc "Object representation of a compiled function"
  alias __MODULE__
  alias Monkex.Instructions

  @enforce_keys [:instructions, :num_locals, :num_params]
  defstruct [:instructions, :num_locals, :num_params]

  @type t() :: %CompiledFunction{}

  @spec from(Instructions.t(), integer(), integer()) :: t()
  def from(instructions, num_locals, num_params),
    do: %CompiledFunction{
      instructions: instructions,
      num_locals: num_locals,
      num_params: num_params
    }

  defimpl Monkex.Object do
    def type(_), do: :compiled_function
  end

  defimpl String.Chars, for: CompiledFunction do
    def to_string(%CompiledFunction{
          num_locals: num_locals,
          instructions: instructions,
          num_params: num_params
        }),
        do:
          "Compiled Function (arity: #{num_params}) (locals: #{num_locals})\nInstructions:\n#{instructions}"
  end
end

defmodule Monkex.Object.Closure do
  @moduledoc "Object representation of a closure that captures free variables and a compiled function"
  alias __MODULE__

  @enforce_keys [:func, :free_objects]
  defstruct [:func, :free_objects]

  @type t() :: %Closure{}

  @spec from(CompiledFunction.t()) :: t()
  def from(func) do
    %Closure{
      func: func,
      free_objects: []
    }
  end

  defimpl Monkex.Object do
    def type(_), do: :closure
  end

  defimpl String.Chars do
    def to_string(%Closure{func: func, free_objects: free}) do
      "Closure with #{length(free)} free variables over #{func}"
    end
  end
end
