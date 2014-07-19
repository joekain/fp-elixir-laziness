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
  def to_list([]), do: []
  def to_list(%Cons{ head: head, tail: tail}), do: [ head.() | to_list(tail) ]

  # Exercise 2
  # Build up a new cons consisting of the elements to take
  def take([], _n), do: []
  def take(%Cons{ head: h, tail: t}, n) do
    if (n > 0), do: %Cons{head: h, tail: take(t, n - 1)}, else: []
  end
end
