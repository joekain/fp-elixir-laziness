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
end
