defmodule Monkex.Parser do
  alias Monkex.Lexer
  alias Monkex.AST
  @enforce_keys [:lexer, :current_token, :next_token]
  defstruct [:lexer, :current_token, :next_token]

  @type t :: %__MODULE__{
          lexer: Monkex.Lexer.t(),
          current_token: Monkex.Token.t() | nil,
          next_token: Monkex.Token.t() | nil
        }

  @spec new(Monkex.Lexer.t()) :: t
  def new(lexer) do
    %Monkex.Parser{
      lexer: lexer,
      current_token: nil,
      next_token: nil
    }
    |> next_token
    |> next_token
  end

  def next_token(parser) do
    {lex, tok} = Lexer.next_token(parser.lexer)

    %Monkex.Parser{
      lexer: lex,
      current_token: parser.next_token,
      next_token: tok
    }
  end


  @spec parse_program(t) :: AST.Program.t
  def parse_program(_parser) do
    nil
  end
end
