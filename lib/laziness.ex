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
  def take(%Cons{head: h, tail: t}, n) do
    if (n > 0), do: %Cons{head: h, tail: take(t, n - 1)}, else: []
  end
  
  def drop([], n), do: []
  def drop(stream, 0), do: stream
  def drop(%Cons{head: _h, tail: t}, n), do: drop(t, n - 1)

  # Exercise 3
  def take_while([], _f), do: []
  def take_while(%Cons{head: h, tail: t}, f) do
    if (f.(h.())), do: %Cons{head: h, tail: take_while(t, f)}, else: []
  end
end
