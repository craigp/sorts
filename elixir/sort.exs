defmodule Random do

  @moduledoc """
  Just a helper module to create random lists of integers for sorting goodness.
  """

  def create_list(limit \\ 100, max \\ 100) do
    :random.seed(:erlang.phash2([node()]), :erlang.monotonic_time(), :erlang.unique_integer())
    for _ <- 1..limit, do: :random.uniform(max)
  end

end

defmodule Bubblesort do

  @moduledoc """
  This bubble sort implementation is obscenely slow and I'm embarrassed to have written it.

  https://en.wikipedia.org/wiki/Bubble_sort
  """

  def sort([]), do: []

  def sort(list) do
    sort(0, list)
  end

  def sort(0, [head, next|tail]) do
    {swapped, swaps} = compare(head, next, 0)
    sort(1, swapped ++ tail, swaps)
  end

  def sort(index, list, 0) when index == length(list) - 1 do
    list
  end

  def sort(index, list, _swaps) when index == length(list) - 1 do
    sort(list)
  end

  def sort(index, list, swaps) do
    case Enum.split(list, index) do
      {done, [head, next|tail]} ->
        {swapped, new_swaps} = compare(head, next, swaps)
        sort(index + 1, done ++ swapped ++ tail, new_swaps)
    end
  end

  def compare(head, next, swaps) when next < head do
    {[next, head], swaps + 1}
  end

  def compare(head, next, swaps) when next >= head do
    {[head, next], swaps}
  end

end

defmodule Bubblesort2 do

  @moduledoc """
  This attempt is about 5x faster than `Bubblesort`, but is still horrendously slow.

  https://en.wikipedia.org/wiki/Bubble_sort
  """

  def sort([]), do: []

  def sort(list) do
    sort(list, [], 0)
  end

  def sort([], new_list, 0) do
    new_list
  end

  def sort([], new_list, _swaps) do
    sort(new_list, [], 0)
  end

  def sort([head, next|tail], new_list, swaps) when length(tail) == 0 do
    {first, second, new_swaps} = compare(head, next, swaps)
    sort([], new_list ++ [first, second], new_swaps)
  end

  def sort([head, next|tail], new_list, swaps) do
    {first, second, new_swaps} = compare(head, next, swaps)
    sort([second] ++ tail, new_list ++ [first], new_swaps)
  end

  def compare(head, next, swaps) when next < head do
    {next, head, swaps + 1}
  end

  def compare(head, next, swaps) when next >= head do
    {head, next, swaps}
  end

end

defmodule Mergesort do

  @moduledoc """
  This is a top-down merge sort, I still need to implement the bottom-up version. Quite a bit
  slower than `Quicksort`, but significantly faster than the others.

  https://en.wikipedia.org/wiki/Merge_sort
  """

  def sort([]), do: []

  def sort(list) do
    merge_sort(:left, list, [], [])
  end

  def merge_sort(_direction, [], left, right) when length(left) > 1 or length(right) > 1 do
    new_left = sort(left)
    new_right = sort(right)
    merge(new_left, new_right, [])
  end

  def merge_sort(_direction, [], left, right) do
    merge(left, right, [])
  end

  def merge_sort(:left, [head|tail], left, right) do
    left = [head] ++ left
    merge_sort(:right, tail, left, right)
  end

  def merge_sort(:right, [head|tail], left, right) do
    right = [head] ++ right
    merge_sort(:left, tail, left, right)
  end

  def merge([], [], result) do
    result
  end

  def merge([left_head|left], [], result) do
    merge(left, [], result ++ [left_head])
  end

  def merge([left_head|left], [right_head|right], result) when left_head <= right_head do
    merge(left, [right_head] ++ right, result ++ [left_head])
  end

  def merge([], [right_head|right], result) do
    merge([], right, result ++ [right_head])
  end

  def merge([left_head|left], [right_head|right], result) do
    merge([left_head] ++ left, right, result ++ [right_head])
  end

end

defmodule Quicksort do

  @moduledoc """
  Pretty damn fast.

  https://en.wikipedia.org/wiki/Quicksort
  """

  def sort([]), do: []

  def sort([head|tail]) do
    {low, high} = Enum.partition(tail, &(&1 < head))
    sort(low) ++ [head] ++ sort(high)
  end

end

defmodule Quicksort2 do

  @moduledoc """
  This seems faster that `Quicksort` on smaller lists, but much slower on larger ones, even
  slower than `Mergesort`. This is likely because `Enum.partition` uses Erlang's `foldl` under
  the skin, which I imagine is more efficient than what I'm doing.

  As a side note, I prefer using overloads with guards to the `if` statements used in the
  Elixir source, I wonder if this is more or less idiomatic?

  https://en.wikipedia.org/wiki/Quicksort
  """

  def sort([]), do: []

  def sort([head|tail]) do
    {low, high} = partition(head, tail, [], [])
    sort(low) ++ [head] ++ sort(high)
  end

  def partition(_pivot, [], low, high) do
    {low, high}
  end

  def partition(pivot, [head|tail], low, high) when head <= pivot do
    partition(pivot, tail, low ++ [head], high)
  end

  def partition(pivot, [head|tail], low, high) do
    partition(pivot, tail, low, high ++ [head])
  end

end

# generate a list of random integers
list = Random.create_list(100)
IO.inspect list: list, length: length(list)

# quick sort
{quicksort_runtime, quicksort} = :timer.tc(fn -> Quicksort.sort(list) end)
IO.inspect quicksort: quicksort, length: length(quicksort), runtime: quicksort_runtime

# quick sort
{quicksort_runtime2, quicksort2} = :timer.tc(fn -> Quicksort2.sort(list) end)
IO.inspect quicksort2: quicksort2, length: length(quicksort2), runtime: quicksort_runtime2
^quicksort2 = Quicksort.sort(list)

# merge sort
{mergesort_runtime, mergesort} = :timer.tc(fn -> Mergesort.sort(list) end)
IO.inspect mergesort: mergesort, length: length(mergesort), runtime: mergesort_runtime
^mergesort = Quicksort.sort(list)

# bubble sort
{bubblesort_runtime, bubblesort} = :timer.tc(fn -> Bubblesort.sort(list) end)
IO.inspect bubblesort: bubblesort, length: length(bubblesort), runtime: bubblesort_runtime
^bubblesort = Quicksort.sort(list)

# bubble sort
{bubblesort2_runtime, bubblesort2} = :timer.tc(fn -> Bubblesort2.sort(list) end)
IO.inspect bubblesort2: bubblesort2, length: length(bubblesort2), runtime: bubblesort2_runtime
^bubblesort2 = Quicksort.sort(list)



