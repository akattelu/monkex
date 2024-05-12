defprotocol Monkex.Object do
  # Type of the object
  def type(obj)
end

defprotocol Monkex.Object.Node do
  def eval(node, env)
end

defmodule Monkex.Object.Integer do
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
    if index >= length(items) do
      {:error, "index out of bounds"}
    else
      {:ok, Enum.at(items, index, Null.object())}
    end
  end

  def push(%Array{items: items}, obj), do: (items ++ [obj]) |> Array.from()
  def head(%Array{items: items}), do: items |> hd
  def tail(%Array{items: items}), do: items |> tl |> Array.from()
  def last(%Array{items: items}), do: items |> List.last()
  def cons(%Array{items: items}, item), do: [item | items] |> Array.from()

  defimpl Monkex.Object, for: Array do
    def type(_), do: :array
  end

  defimpl String.Chars, for: Array do
    def to_string(%Array{items: items}), do: "[#{Enum.join(items, ", ")}]"
  end
end

defmodule Monkex.Object.Dictionary do
  alias __MODULE__
  alias Monkex.Object.Null
  @enforce_keys [:map]
  defstruct [:map]

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
  alias Monkex.Object.Array
  alias Monkex.Object.Integer
  alias Monkex.Object.String, as: StringObj
  alias Monkex.Object.Null
  defstruct [:param_count, :handler]

  def len([%Array{items: items} | _]), do: length(items) |> Integer.from()
  def len([%StringObj{value: value} | _]), do: String.length(value) |> Integer.from()

  def puts([obj | _]) do
    IO.puts("#{obj}")
    Null.object()
  end

  def char_at([%StringObj{value: str} | [%Integer{value: int} | _]]) do
    str |> String.at(int) |> String.Chars.to_string() |> StringObj.from()
  end

  def push([%Array{} = arr | [val | _]]) do
    Array.push(arr, val)
  end

  def head([%Array{} = arr | _]), do: Array.head(arr)
  def tail([%Array{} = arr | _]), do: Array.tail(arr)
  def last([%Array{} = arr | _]), do: Array.last(arr)
  def cons([%Array{} = arr | [obj | _]]), do: Array.cons(arr, obj)
end
