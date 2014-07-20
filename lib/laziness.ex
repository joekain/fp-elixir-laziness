defmodule Laziness do
  defmodule Cons do
    defstruct head: nil, tail: nil
  end
  
  defmacrop ld(x) do
    quote do
      fn -> unquote(x) end
    end
  end
  
  # Use a macro for lazy evaluation
  defmacro cons(h, t) do
    quote do
      %Cons{ head: fn () -> unquote(h) end, tail: fn () -> unquote(t) end }
    end
  end
  
  defp terminal, do: fn -> [] end
  
  # Exercise 1
  def to_list([]), do: []
  def to_list(%Cons{ head: h, tail: t}), do: [ h.() | to_list(t.()) ]

  # Exercise 2
  # Build up a new cons consisting of the elements to take
  def take([], _n), do: []
  def take(%Cons{head: h, tail: t}, n) do
    if (n > 0), do: %Cons{head: h, tail: ld( take(t.(), n - 1) )}, else: []
  end
  
  def drop([], n), do: []
  def drop(stream, 0), do: stream
  def drop(%Cons{head: _h, tail: t}, n), do: drop(t.(), n - 1)

  # Exercise 3
  def take_while([], _f), do: []
  def take_while(%Cons{head: h, tail: t}, f) do
    if (f.(h.())), do: %Cons{head: h, tail: take_while(t.(), f)}, else: terminal
  end
  
  # Adapted from the text
  def fold_right([], acc, _f), do: acc
  def fold_right(%Cons{head: h, tail: t}, acc, f) do
    f.(h.(), fn -> fold_right(t.(), acc, f) end)
  end
  
  # Exercise 4
  def for_all(s, f), do: fold_right(s, true, fn
    (x, acc) -> f.(x) && acc.() end
  )
  
  # Exercise 5
  def take_while_via_fold(l, f), do: fold_right(l, [], fn
    (x, acc) -> if  f.(x), do: [x | acc.()], else: [] end
  )

  # This is an adaptation of the version given in the text
  # def head_option([]), do: {:error, "Empty list"}
  # def head_option([h, _t]), do: {:ok, h.()}

  # This is my version written using fold_right.
  def head_option(l), do: fold_right(l, {:error, "Empty list"}, fn
    (x, acc) -> {:ok, x} end
  )
  
  # Exercise 7 - map
  # I realize I've made a mistake, tail needs to be lazy
  def map(s, f), do: fold_right(s, [], fn
    (x, acc) -> %Cons{head: ld(f.(x)), tail: acc} end
  )

end
