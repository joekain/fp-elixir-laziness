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
    case f.(acc) do
      nil -> []
      {v, new_acc} -> cons(v, unfold(new_acc, f))
    end
  end
  
  # Exercise 12 - fibs using unfold
  def fibs_via_unfold(), do: unfold({0, 1}, fn ({n, m}) -> {n, {m, n + m}} end)
  
  # Exercise 12 - from_via_unfold
  def from_via_unfold(n), do: unfold(n, fn (x) -> {x, x + 1} end)
  
  # Exercise 12 - constant_via_unfold
  def constant_via_unfold(n), do: unfold(n, fn (x) -> {x, x} end)
  
  # Exercise 12 - ones_via_unfold
  def ones_via_unfold, do: constant_via_unfold(1)


  # Exercise 13 - map_via_unfold
  def map_via_unfold(s, f), do: unfold(s, fn
    ([]) -> nil
    (%Cons{head: h, tail: t}) -> { f.(h.()), t.() } end
  )
  
  # Exercise 13 - take_via_unfold
  def take_via_unfold(s, n), do: unfold({s, n}, fn
    ({_s, 0}) -> nil
    ({%Cons{head: h, tail: t}, n}) -> {h.(), {t.(), n - 1}}
  end)
  
  # Exercise 13 - take_via_unfold
  def take_while_via_unfold(s, f), do: unfold({s, f}, fn
    ({[], f}) -> nil
    ({%Cons{head: h, tail: t}, f}) -> if f.(h.()), do: {h.(), {t.(), f}}, else: nil
  end)
  
  # Excercise 13 - zip_via_unfold
  def zip_via_unfold(s1, s2), do: unfold({s1, s2}, fn
    ({[],_}) -> nil
    ({_,[]}) -> nil
    ({ %Cons{head: h1, tail: t1}, %Cons{head: h2, tail: t2} }) -> { {h1.(), h2.()}, {t1.(), t2.()} }
  end)
  
  # Excercise 13 - zip_all_via_unfold
  def zip_all_via_unfold(s1, s2), do: unfold({s1, s2}, fn
    ({[],[]}) -> nil
    ({ [],%Cons{head: h2, tail: t2} }) -> {{ :error, {:ok, h2.()} }, {[], t2.()} }
    ({ %Cons{head: h1, tail: t1},[] }) -> {{ {:ok, h1.()}, :error }, {t1.(), []} }
    ({ %Cons{head: h1, tail: t1}, %Cons{head: h2, tail: t2} }) -> {{ {:ok, h1.()}, {:ok, h2.()} }, {t1.(), t2.()} }
  end)
  
  
  # Exercise 14 - starts_with
  def starts_with(s, prefix), do: zip_all_via_unfold(s, prefix)
    |> foldr(ld(true), fn 
      ({ {:ok, _a}, :error },    _acc) -> true
      ({ {:ok, a}, {:ok, a} },    acc) -> acc.()
      ({ {:ok, _a}, {:ok, _b} }, _acc) -> false
  end)
  
  # Exercise 15 - tails
  def tails(s), do: unfold(s, fn
    ([]) -> nil
    (%Cons{head: h, tail: t}) -> { cons(h.(), t.()), t.() }
  end)
  
  
  # Exercise 16 - scan
  #   Can this be implemented using unfold?  I don't think it can be implemented
  #   using unfold efficiently as unfold runs through the list in the wrong order
  #   which would make it impossible to reuse the partial results.
  
  # Here's an inefficient version using unfold.  It calls foldr each time and isn't able to reuse the result.
  # def scan(s, acc, f), do: unfold(s, fn
  #   (:terminate) -> nil
  #   ([]) -> {0, :terminate}
  #   (%Cons{head: h, tail: t}) -> { foldr(cons(h.(), t.()), ld(acc), fn (x, acc) -> f.(x, acc.()) end), t.() }
  # end)
  
  # I tried using foldr and build something the same as the above.  Then I tried a direct recursive solution but it is
  # also inefficient.  I ended writing a specific test to determine that this was inefficient.
  # def scan([], acc, f), do: cons(acc, [])
  # def scan(%Cons{head: h, tail: t}, acc, f) do
  #   IO.puts "scan #{h.()}"
  #   %Cons{head: next_h, tail: next_t} = scan(t.(), acc, f)
  #   cons(f.(h.(), next_h.()), %Cons{head: next_h, tail: next_t})
  # end
  
  # I finally looked at the text's solution which uses foldr.  The key is to have more state in the fold than just the 
  # resulting stream.  Then extract the stream and return it.
  # In this case the foldr builds up a tuple containing the running total and the accumulated stream.
  def scan(s, initial, f) do
    {_total, result} = foldr(s, ld({initial, cons(initial, [])}),
      fn 
      (x, lazy) ->
        {val, acc} = lazy.()
        head = f.(x, val)
        {head, cons(head, acc)}
      end
    )
    result
  end
end
