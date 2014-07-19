defmodule Laziness do
  defmodule Cons do
    defstruct head: nil, tail: nil
  end
  
  # Use a macro for lazy evaluation
  defmacro cons(h, t) do
    quote do
      %Cons{ head: fn () -> unquote(h) end, tail: unquote(t) }
    end
  end
  
  # Exercise 1
  def to_list([]), do: [ ]
  def to_list(%Cons{ head: head, tail: tail}), do: [ head.() | to_list(tail) ]

end
