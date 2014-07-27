defmodule LazinessTest do
  use ExUnit.Case
  
  require Laziness

  alias Laziness, as: L

  def build_stream do
    L.cons(1, L.cons(2, L.cons(3, [])))
  end

  def build_stream_with_sentinel do
    L.cons(1, L.cons(2, L.cons(3, L.cons(raise("sentinel reached"), []))))
  end
  
  def build_infinite_stream_of_ones do
    L.cons(1, build_infinite_stream_of_ones)
  end
  
  test "convert stream to list" do
    assert L.to_list(build_stream) == [1, 2, 3]
  end
  
  test "convert empty stream to list" do
    assert L.to_list([]) == []
  end
  
  test "take" do
    assert L.take(build_stream_with_sentinel, 2) |>  L.to_list == [1, 2]
  end

  test "drop" do
    assert L.drop(build_stream, 2)|> L.to_list == [3]
  end

  test "take_while" do
    assert L.take_while(build_stream_with_sentinel, &(&1 < 2)) |> L.to_list == [1]
  end

  test "for_all with matching stream" do
    assert L.for_all(build_stream, &(&1 < 4)) == true
  end

  test "for_all with non-matching stream" do
    assert L.for_all(build_stream_with_sentinel, &(&1 < 2)) == false
  end

  test "take_while_via_fold" do
    assert L.take_while_via_fold(build_stream_with_sentinel, &(&1 < 2)) |> L.to_list == [1]
  end
  
  test "take_while_via_fold for an entire stream" do
    assert L.take_while_via_fold(build_stream, fn (_x) -> true end) |> L.to_list == [1, 2, 3]
  end

  test "head_option" do
    assert L.head_option(build_stream_with_sentinel) == {:ok, 1}
  end

  test "head_option with empty list" do
    assert L.head_option([]) == {:error, "Empty list"}
  end

  test "map" do
    assert L.map(build_stream, &(&1 * &1))|> L.to_list == [1, 4, 9]
  end

  test "map is lazy" do
    assert L.map(build_stream_with_sentinel, &(&1 * &1)) |> L.take(2) |> L.to_list == [1, 4]
  end

  test "filter" do
    assert L.filter(build_stream, &(&1 < 3)) |> L.to_list == [1, 2]
  end

  test "filter is lazy" do
    assert L.filter(build_stream_with_sentinel, &(&1 < 3)) |> L.take(2) |> L.to_list == [1, 2]
  end

  test "append" do
    assert L.append(build_stream, fn -> build_stream end) |> L.to_list == [1, 2, 3, 1, 2, 3]
  end
  
  test "flat_map" do
    fun = fn
      (x) -> L.cons(x, L.cons(x*x, []))
    end
    assert L.flat_map(build_stream, fun)|> L.to_list == [1, 1, 2, 4, 3, 9]
  end
  
  test "flat_map is lazy" do
    fun = fn
      (x) -> L.cons(x, L.cons(x*x, []))
    end
    assert L.flat_map(build_stream_with_sentinel, fun)|> L.take(6) |> L.to_list == [1, 1, 2, 4, 3, 9]
  end
  
  test "map is lazy on infinite streams" do
    assert L.map(build_infinite_stream_of_ones, &(&1 * 2)) |> L.take(5) |> L.to_list == [2, 2, 2, 2, 2]
  end
  
  test "take_while is lazy on infinite streams" do
    assert L.take_while_via_fold(build_infinite_stream_of_ones, &(&1 == 1)) |> L.take(5) |> L.to_list == [1, 1, 1, 1, 1]
  end

  test "for_all is lazy on infinite streams" do
    assert L.for_all(build_infinite_stream_of_ones, &(&1 != 1)) == false
  end
  
  test "build_stream_of_constant" do
    assert L.build_stream_of_constant(7) |> L.take(5) |> L.to_list == [7, 7, 7, 7, 7]
  end
  
  test "build_counting_stream" do
    assert L.build_counting_stream(7) |> L.take(5) |> L.to_list == [7, 8, 9, 10, 11]
  end
  
  test "build_fib_stream" do
    assert L.build_fib_stream |> L.take(7) |> L.to_list == [0, 1, 1, 2, 3, 5, 8]
  end
  
  test "unfold" do
    assert L.unfold(1, &({&1 * &1, &1 + 1})) |> L.take(5) |> L.to_list == [1, 4, 9, 16, 25]
  end
  
  test "unfold should terminate when function returns nil" do
    assert L.unfold(1, fn
      (6) -> nil
      (x) -> {x, x + 1}
    end) |> L.to_list == [1, 2, 3, 4, 5]
  end
  
  test "fibs_via_unfold" do
    assert L.fibs_via_unfold |> L.take(7) |> L.to_list == [0, 1, 1, 2, 3, 5, 8]
  end

  test "from_via_unfold" do
    assert L.from_via_unfold(7) |> L.take(5) |> L.to_list == [7, 8, 9, 10, 11]
  end
  
  test "constant_via_unfold" do
    assert L.constant_via_unfold(7) |> L.take(5) |> L.to_list == [7, 7, 7, 7, 7]
  end
  
  test "ones_via_unfold" do
    assert L.ones_via_unfold |> L.take(5) |> L.to_list == [1, 1, 1, 1, 1]
  end

  test "map_via_unfold" do
    assert L.map_via_unfold(build_stream, &(&1 * &1))|> L.to_list == [1, 4, 9]
  end

  test "map_via_unfold is lazy" do
    assert L.map_via_unfold(build_stream_with_sentinel, &(&1 * &1)) |> L.take(2) |> L.to_list == [1, 4]
  end
  
  test "map_via_unfold is lazy on infinite streams" do
    assert L.map_via_unfold(build_infinite_stream_of_ones, &(&1 * 2)) |> L.take(5) |> L.to_list == [2, 2, 2, 2, 2]
  end
  
  test "take_via_unfold" do
    assert L.take_via_unfold(build_stream_with_sentinel, 3) |>  L.to_list == [1, 2, 3]
  end
  
  test "take_while_via_unfold" do
    assert L.take_while_via_unfold(build_stream_with_sentinel, &(&1 < 2)) |> L.to_list == [1]
  end
  
  test "take_while_via_unfold for an entire stream" do
    assert L.take_while_via_unfold(build_stream, fn (_x) -> true end) |> L.to_list == [1, 2, 3]
  end
  
  test "zip_via_unfold for infinite streams" do
    assert L.zip_via_unfold(L.fibs_via_unfold, L.constant_via_unfold(3))
           |> L.take(3) |> L.to_list == [{0,3}, {1,3}, {1,3}]
  end
  
  test "zip_via_unfold for finite streams" do
    assert L.zip_via_unfold(build_stream, build_stream) |> L.to_list == [{1, 1,}, {2, 2,}, {3, 3}]
  end
  
  test "zip_all_via_unfold" do
    assert L.zip_all_via_unfold(build_stream, build_infinite_stream_of_ones) |> L.take(4)
           |> L.to_list == [{{:ok, 1}, {:ok, 1},}, {{:ok, 2}, {:ok, 1},}, {{:ok, 3}, {:ok, 1}}, {:error, {:ok, 1}}]
  end
  
  test "zip_all_via_unfold streams reversed" do
    assert L.zip_all_via_unfold(build_infinite_stream_of_ones, build_stream) |> L.take(4)
           |> L.to_list == [{{:ok, 1}, {:ok, 1},}, {{:ok, 1}, {:ok, 2},}, {{:ok, 1}, {:ok, 3}}, {{:ok, 1}, :error}]
  end
  
  test "zip_all_via_unfold infinite streams lists" do
    assert L.zip_all_via_unfold(build_infinite_stream_of_ones, build_infinite_stream_of_ones) |> L.take(4)
           |> L.to_list == [{{:ok, 1}, {:ok, 1},}, {{:ok, 1}, {:ok, 1},}, {{:ok, 1}, {:ok, 1}}, {{:ok, 1}, {:ok, 1}}]
  end
  
  test "starts_with" do
    assert L.starts_with(build_stream, L.cons(1, L.cons(2, []))) == true
  end
  
  test "starts_with on an infinite stream" do
    assert L.starts_with(build_infinite_stream_of_ones, L.cons(1, L.cons(1, []))) == true
  end

  test "starts_with with mismatched stream" do
    assert L.starts_with(build_infinite_stream_of_ones, L.cons(1, L.cons(2, []))) == false
  end
  
  test "tails" do
    assert L.tails(build_stream) |> L.flat_map(&(&1)) |> L.to_list == [1, 2, 3,  2, 3,  3]
  end
  
  test "scan" do
    assert L.scan(build_stream, 0, &(&1 + &2)) |> L.to_list == [6, 5, 3, 0]
  end

  test "scan should reuse intermediate results" do
    {:ok, counter} = Agent.start_link(fn -> 0 end)
    count_calls = fn
      (_, _) -> Agent.get_and_update(counter, fn (current) -> {current + 1, current + 1} end)

    end

    assert L.scan(build_stream, 0, count_calls) |> L.to_list == [3, 2, 1, 0]
  end
end
