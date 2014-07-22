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
  
  def terminal, do: fn -> [] end
  
  # Exercise 1
  def to_list([]), do: []
  def to_list(%Cons{ head: h, tail: t}), do: [ h.() | to_list(t.()) ]

  # Exercise 2
  # Build up a new cons consisting of the elements to take
  def take([], _n), do: []
  def take(%Cons{head: h, tail: t}, n) when n <= 1, do: %Cons{head: h, tail: terminal}
  def take(%Cons{head: h, tail: t}, n) when n > 1, do: %Cons{head: h, tail: ld( take(t.(), n - 1) )}
  
  def drop([], _n), do: []
  def drop(stream, 0), do: stream
  def drop(%Cons{head: _h, tail: t}, n), do: drop(t.(), n - 1)

  # Exercise 3
  def take_while([], _f), do: []
  def take_while(%Cons{head: h, tail: t}, f) do
    if (f.(h.())), do: %Cons{head: h, tail: take_while(t.(), f)}, else: terminal
  end
  
  # Adapted from the text
  # It wasn't until I worked through problems with append in Ex7 that I realized
  # I needed to evaluate acc.() in the base case.
  def foldr([], acc, _f), do: acc.()
  def foldr(%Cons{head: h, tail: t}, acc, f) do
    f.(h.(), fn -> foldr(t.(), acc, f) end)
  end
  
  # Exercise 4
  def for_all(s, f), do: foldr(s, ld(true), fn
    (x, acc) -> f.(x) && acc.() end
  )
  
  # Exercise 5
  def take_while_via_fold(l, f), do: foldr(l, terminal, fn
    (x, acc) -> if  f.(x), do: cons(x, acc.()), else: [] end
  )

  # This is an adaptation of the version given in the text
  # def head_option([]), do: {:error, "Empty list"}
  # def head_option([h, _t]), do: {:ok, h.()}

  # This is my version written using foldr.
  def head_option(l), do: foldr(l, ld({:error, "Empty list"}), fn
    (x, _acc) -> {:ok, x} end
  )
  
  # Exercise 7 - map
   def map(s, f), do: foldr(s, terminal, fn
    (x, acc) -> %Cons{head: ld(f.(x)), tail: acc} end
  )
  
  # Exercise 7 - filter
  def filter(s, f), do: foldr(s, terminal, fn
    (x, acc) -> if f.(x), do: cons(x, acc.()), else: acc.() end
  )
    
  # Exercise 7 - append
  def append(s1, s2), do: foldr(s1, s2, fn
    (x, acc) -> cons(x, acc.()) end
  )
  
  # Exercise 7 - flat_map
  # f.(x) will return a Cons and we must apend the acc to the new Cons
  def flat_map(s, f), do: foldr(s, terminal, fn
    (x, acc) -> append(f.(x), acc) end
  )
  
  # Exercise 8 - general constant stream
  def build_stream_of_constant(n), do: cons(n, build_stream_of_constant(n))
  
  # Exercise 9 - counting stream
  def build_counting_stream(n), do: cons(n, build_counting_stream(n + 1))
  
  # Exercise 10 - fibs
  def build_fib_stream(n \\ 0, m \\ 1), do: cons(n, build_fib_stream(m, n + m))
  
  # Exercise 11 - unfold
  def unfold(acc, f) do
    {v, new_acc} = f.(acc)
    cons(v, unfold(new_acc, f))
  end
end
