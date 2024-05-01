defprotocol Monkex.Object do
  # Type of the object
  def type(obj) 
end

defprotocol Monkex.Object.Node do
  def eval(node)
end

defmodule Monkex.Object.Integer do
  defstruct [:value]
end

defimpl Monkex.Object, for: Monkex.Object.Integer do
  def type(_), do: :integer
end

defimpl String.Chars, for: Monkex.Object.Integer do
  def to_string(obj), do: "#{obj.value}"
end

defmodule Monkex.Object.Boolean do
  alias __MODULE__
  defstruct [:value]

  def yes() do
    %Boolean{value: true}
  end

  def no() do
    %Boolean{value: false}
  end
end

defimpl Monkex.Object, for: Monkex.Object.Boolean do
  def type(_), do: :boolean
end

defimpl String.Chars, for: Monkex.Object.Boolean do
  def to_string(obj), do: "#{obj.value}"
end

defmodule Monkex.Object.Null do
  alias __MODULE__
  defstruct []

  def object() do
    %Null{}
  end
end

defimpl Monkex.Object, for: Monkex.Object.Null do
  def type(_), do: :null
end

defimpl String.Chars, for: Monkex.Object.Null do
  def to_string(_), do: "NULL"
end
