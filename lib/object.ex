defprotocol Monkex.Object do
  # Type of the object
  def type(obj)
end

defprotocol Monkex.Object.Node do
  def eval(node)
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


  def from(%ReturnValue{} = x) do x end
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

  def with_message(msg), do: %Error{message:  msg}

  defimpl Monkex.Object, for: Error do
    def type(_), do: :error
  end

  defimpl String.Chars, for: Error do
    def to_string(%Error{message: msg}), do: "Error: #{msg}"
  end
end
