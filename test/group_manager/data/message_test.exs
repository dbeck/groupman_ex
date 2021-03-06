defmodule GroupManager.Data.MessageTest do

  use ExUnit.Case
  require GroupManager.Data.Message
  alias GroupManager.Data.Message
  alias GroupManager.Data.LocalClock
  alias GroupManager.Data.WorldClock
  alias GroupManager.Data.TimedSet
  alias GroupManager.Data.TimedItem
  alias GroupManager.Data.Item
  alias Chatter.NetID

  defp dummy_me do
    NetID.new({1,2,3,4},1)
  end

  defp dummy_other do
    NetID.new({2,3,4,5},2)
  end

  defp dummy_third do
    NetID.new({3,4,5,6},3)
  end

  test "basic test for new" do
    assert Message.valid?(Message.new("hello"))
  end

  test "basic test for invalid input" do
    assert Message.valid?(nil) == false
    assert Message.valid?([]) == false
    assert Message.valid?({}) == false
    assert Message.valid?(:ok) == false
    assert Message.valid?({:ok}) == false
    assert Message.valid?({:message}) == false
    assert Message.valid?({:message, nil}) == false
    assert Message.valid?({:message, nil, nil}) == false
    assert Message.valid?({:message, nil, nil, nil}) == false
  end

  test "check if a newly created object is empty" do
    m = Message.new("hello")
    assert Message.empty?(m)
  end

  test "checking for emptiness on an invalid object leads to exception" do
    assert_raise FunctionClauseError, fn -> Message.empty?(:ok) end
    assert_raise FunctionClauseError, fn -> Message.empty?([]) end
    assert_raise FunctionClauseError, fn -> Message.empty?({}) end
    assert_raise FunctionClauseError, fn -> Message.empty?(nil) end
  end

  test "time() returns an empty and valid WorldClock for new objects" do
    t = Message.new("hello") |> Message.time
    assert WorldClock.valid?(t)
    assert WorldClock.empty?(t)
  end

  test "time() raises on invalid objects" do
    assert_raise FunctionClauseError, fn -> Message.time(:ok) end
    assert_raise FunctionClauseError, fn -> Message.time([]) end
    assert_raise FunctionClauseError, fn -> Message.time({}) end
    assert_raise FunctionClauseError, fn -> Message.time(nil) end
  end

  test "items() returns an empty and valid TimedSet for new objects" do
    t = Message.new("hello") |> Message.items
    assert TimedSet.valid?(t)
    assert TimedSet.empty?(t)
  end

  test "items() raises on invalid objects" do
    assert_raise FunctionClauseError, fn -> Message.items(:ok) end
    assert_raise FunctionClauseError, fn -> Message.items([]) end
    assert_raise FunctionClauseError, fn -> Message.items({}) end
    assert_raise FunctionClauseError, fn -> Message.items(nil) end
  end

  test "can add() a valid TimedItem" do
    local = LocalClock.new(dummy_me) |> LocalClock.next
    timed_item = Item.new(dummy_me) |> TimedItem.construct(local)
    m = Message.new("hello") |> Message.add(timed_item)
    assert "hello" == Message.group_name(m)
    assert Message.valid?(m) == true
    assert Message.empty?(m) == false
    assert [timed_item] == Message.items(m) |> TimedSet.items
    assert [local] == Message.time(m) |> WorldClock.time
  end

  test "add() raises for invalid item or invalid message" do
    m = Message.new("hello")
    assert_raise FunctionClauseError, fn -> Message.add(m, :ok) end
    assert_raise FunctionClauseError, fn -> Message.add(m, []) end
    assert_raise FunctionClauseError, fn -> Message.add(m, {}) end
    assert_raise FunctionClauseError, fn -> Message.add(m, nil) end

    local = LocalClock.new(dummy_me) |> LocalClock.next
    timed_item = Item.new(dummy_me) |> TimedItem.construct(local)

    assert_raise FunctionClauseError, fn -> Message.add(:ok, timed_item) end
    assert_raise FunctionClauseError, fn -> Message.add([], timed_item) end
    assert_raise FunctionClauseError, fn -> Message.add({}, timed_item) end
    assert_raise FunctionClauseError, fn -> Message.add(nil, timed_item) end
  end

  test "add() updates both the world clock and the timed set" do
    timed_item1 = Item.new(dummy_me)    |> TimedItem.construct(LocalClock.new(dummy_me))
    timed_item2 = Item.new(dummy_other) |> TimedItem.construct(LocalClock.new(dummy_other))
    timed_item3 = Item.new(dummy_third) |> TimedItem.construct(LocalClock.new(dummy_third))

    m = Message.new("hello") |> Message.add(timed_item1)

    assert 1 == Message.time(m)  |> WorldClock.count(dummy_me)
    assert 1 == Message.items(m) |> TimedSet.count(dummy_me)
    assert 0 == Message.time(m)  |> WorldClock.count(dummy_other)
    assert 0 == Message.items(m) |> TimedSet.count(dummy_other)

    m = m |> Message.add(timed_item2)

    assert 1 == Message.time(m)  |> WorldClock.count(dummy_me)
    assert 1 == Message.items(m) |> TimedSet.count(dummy_me)
    assert 1 == Message.time(m)  |> WorldClock.count(dummy_other)
    assert 1 == Message.items(m) |> TimedSet.count(dummy_other)

    m = m |> Message.add(timed_item3)

    assert 1 == Message.time(m)  |> WorldClock.count(dummy_me)
    assert 1 == Message.items(m) |> TimedSet.count(dummy_me)
    assert 1 == Message.time(m)  |> WorldClock.count(dummy_other)
    assert 1 == Message.items(m) |> TimedSet.count(dummy_other)
    assert 1 == Message.time(m)  |> WorldClock.count(dummy_third)
    assert 1 == Message.items(m) |> TimedSet.count(dummy_third)
  end

  test "merge() updates both the world clock and the timed set" do
    timed_item1 = Item.new(dummy_me)    |> TimedItem.construct(LocalClock.new(dummy_me))
    timed_item2 = Item.new(dummy_other) |> TimedItem.construct(LocalClock.new(dummy_other))
    timed_item3 = Item.new(dummy_third) |> TimedItem.construct(LocalClock.new(dummy_third))

    m1 = Message.new("hello") |> Message.add(timed_item1)
    m2 = Message.new("hello") |> Message.add(timed_item2)
    m3 = Message.new("hello") |> Message.add(timed_item3)

    # merge is idempotent w/ respect to world clock and items
    assert 1 == Message.merge(m1,m1) |> Message.time  |> WorldClock.count(dummy_me)
    assert 1 == Message.merge(m1,m1) |> Message.items |> TimedSet.count(dummy_me)

    # merge keeps both elements
    m12 = Message.merge(m1,m2)
    assert 1 == m12 |> Message.time  |> WorldClock.count(dummy_me)
    assert 1 == m12 |> Message.items |> TimedSet.count(dummy_me)
    assert 1 == m12 |> Message.time  |> WorldClock.count(dummy_other)
    assert 1 == m12 |> Message.items |> TimedSet.count(dummy_other)

    # merge keeps all 3 elements
    m123 = Message.merge(m12, m3)
    assert 1 == m123 |> Message.time  |> WorldClock.count(dummy_me)
    assert 1 == m123 |> Message.items |> TimedSet.count(dummy_me)
    assert 1 == m123 |> Message.time  |> WorldClock.count(dummy_other)
    assert 1 == m123 |> Message.items |> TimedSet.count(dummy_other)
    assert 1 == m123 |> Message.time  |> WorldClock.count(dummy_third)
    assert 1 == m123 |> Message.items |> TimedSet.count(dummy_third)

    # merge keeps overlapping elemnts too
    m23 = Message.merge(m2,m3)
    m1223 = Message.merge(m12, m23)
    assert 1 == m1223 |> Message.time  |> WorldClock.count(dummy_me)
    assert 1 == m1223 |> Message.items |> TimedSet.count(dummy_me)
    assert 1 == m1223 |> Message.time  |> WorldClock.count(dummy_other)
    assert 1 == m1223 |> Message.items |> TimedSet.count(dummy_other)
    assert 1 == m1223 |> Message.time  |> WorldClock.count(dummy_third)
    assert 1 == m1223 |> Message.items |> TimedSet.count(dummy_third)
  end

  # group_name
  test "group_name() raises on invalid input" do
    assert_raise FunctionClauseError, fn -> Message.group_name(:ok) end
    assert_raise FunctionClauseError, fn -> Message.group_name([]) end
    assert_raise FunctionClauseError, fn -> Message.group_name({}) end
    assert_raise FunctionClauseError, fn -> Message.group_name(nil) end
  end

  test "group_name() returns the name it was set to" do
    m1 = Message.new("hello")
    assert "hello" == Message.group_name(m1)
  end

  test "merge() is idempotent" do
    timed_item1 = Item.new(dummy_me)    |> TimedItem.construct(LocalClock.new(dummy_me))
    timed_item2 = Item.new(dummy_other) |> TimedItem.construct(LocalClock.new(dummy_other))

    m1 = Message.new("hello") |> Message.add(timed_item1)
    m2 = Message.new("hello") |> Message.add(timed_item2)

    assert m2 == Message.merge(m2,m2)
    assert m2 == Message.merge(m2,m2) |> Message.merge(m2)

    m12 = Message.merge(m1,m2)
    assert m12 == Message.merge(m12,m1)
    assert m12 == Message.merge(m12,m2)
    assert m12 == Message.merge(m12,m1) |> Message.merge(m1)
    assert m12 == Message.merge(m12,m2) |> Message.merge(m2)
  end

  test "merge() raises for invalid input" do
    m = Message.new("hello")
    assert_raise FunctionClauseError, fn -> Message.merge(m, :ok) end
    assert_raise FunctionClauseError, fn -> Message.merge(m, []) end
    assert_raise FunctionClauseError, fn -> Message.merge(m, {}) end
    assert_raise FunctionClauseError, fn -> Message.merge(m, nil) end

    assert_raise FunctionClauseError, fn -> Message.merge(:ok, m) end
    assert_raise FunctionClauseError, fn -> Message.merge([], m) end
    assert_raise FunctionClauseError, fn -> Message.merge({}, m) end
    assert_raise FunctionClauseError, fn -> Message.merge(nil, m) end
  end

  test "count() raises for invalid input" do
    m = Message.new("hello")
    id = dummy_me
    assert_raise FunctionClauseError, fn -> Message.count(m, id, :ok) end
    assert_raise FunctionClauseError, fn -> Message.count(m, id, []) end
    assert_raise FunctionClauseError, fn -> Message.count(m, id, {}) end
    assert_raise FunctionClauseError, fn -> Message.count(m, id, nil) end

    assert_raise FunctionClauseError, fn -> Message.count(:ok, id, :add) end
    assert_raise FunctionClauseError, fn -> Message.count([], id, :add) end
    assert_raise FunctionClauseError, fn -> Message.count({}, id, :add) end
    assert_raise FunctionClauseError, fn -> Message.count(nil, id, :add) end

    assert_raise FunctionClauseError, fn -> Message.count(m, :ok, :add) end
    assert_raise FunctionClauseError, fn -> Message.count(m, [], :add) end
    assert_raise FunctionClauseError, fn -> Message.count(m, {}, :add) end
    assert_raise FunctionClauseError, fn -> Message.count(m, nil, :add) end
  end

  test "members() raises on invalid input" do
    assert_raise FunctionClauseError, fn -> Message.members(:ok) end
    assert_raise FunctionClauseError, fn -> Message.members([]) end
    assert_raise FunctionClauseError, fn -> Message.members({}) end
    assert_raise FunctionClauseError, fn -> Message.members(nil) end
  end

  test "topology() raises on invalid input" do
    assert_raise FunctionClauseError, fn -> Message.topology(:ok) end
    assert_raise FunctionClauseError, fn -> Message.topology([]) end
    assert_raise FunctionClauseError, fn -> Message.topology({}) end
    assert_raise FunctionClauseError, fn -> Message.topology(nil) end
  end

  test "merge() keeps the latest elements" do
    timed_item1 = Item.new(dummy_me)    |> TimedItem.construct(LocalClock.new(dummy_me))
    timed_item2 = Item.new(dummy_other) |> TimedItem.construct(LocalClock.new(dummy_other))

    m1 = Message.new("hello") |> Message.add(timed_item1)
    m2 = Message.new("hello") |> Message.add(timed_item2)

    timed_item1x = Item.new(dummy_me)    |> TimedItem.construct_next(LocalClock.new(dummy_me))
    timed_item2x = Item.new(dummy_other) |> TimedItem.construct_next(LocalClock.new(dummy_other))

    m1x = Message.new("hello") |> Message.add(timed_item1x)
    m2x = Message.new("hello") |> Message.add(timed_item2x)

    m12 = Message.merge(m1,m2)
    m1x2 = Message.merge(m1x,m2)
    m12x = Message.merge(m1,m2x)
    m1x2x = Message.merge(m1x,m2x)

    assert m1x2 == Message.merge(m1,m1x) |> Message.merge(m2)
    assert m1x2 == Message.merge(m1,m2)  |> Message.merge(m1x)
    assert m1x2 == Message.merge(m1x,m2) |> Message.merge(m1)

    assert m12x == Message.merge(m2,m2x) |> Message.merge(m1)
    assert m12x == Message.merge(m1,m2)  |> Message.merge(m2x)
    assert m12x == Message.merge(m1,m2x) |> Message.merge(m2)

    assert m1x2x == Message.merge(m12,m1x)  |> Message.merge(m2x)
    assert m1x2x == Message.merge(m12x,m1x) |> Message.merge(m2)
    assert m1x2x == Message.merge(m1x2,m1)  |> Message.merge(m2x)
    assert m1x2x == Message.merge(m1x2,m1)  |> Message.merge(m2x)
    assert m1x2x == Message.merge(m1x2,m2)  |> Message.merge(m2x)
    assert m1x2x == Message.merge(m1x2,m2x) |> Message.merge(m2)
    assert m1x2x == Message.merge(m1x2,m2x) |> Message.merge(m1)
  end

  test "members() returns all NetIDs" do
    timed_item1 = Item.new(dummy_me)    |> TimedItem.construct(LocalClock.new(dummy_me))
    timed_item2 = Item.new(dummy_other) |> TimedItem.construct(LocalClock.new(dummy_other))

    m1 = Message.new("hello") |> Message.add(timed_item1)
    m2 = Message.new("hello") |> Message.add(timed_item2)
    m12 = Message.merge(m1,m2)

    assert [dummy_me] == Message.members(m1)
    assert [dummy_other] == Message.members(m2)
    assert [dummy_me,dummy_other] == Message.members(m12) |> Enum.sort
  end

  test "count() works for all NetIDs" do
    timed_item1 = Item.new(dummy_me)    |> Item.op(:add) |> TimedItem.construct(LocalClock.new(dummy_me))
    timed_item2 = Item.new(dummy_other) |> Item.op(:get) |> TimedItem.construct(LocalClock.new(dummy_other))

    m1 = Message.new("hello") |> Message.add(timed_item1)
    m2 = Message.new("hello") |> Message.add(timed_item2)
    m12 = Message.merge(m1,m2)

    assert 1 == Message.count(m1,dummy_me,:add)
    assert 0 == Message.count(m1,dummy_me,:get)
    assert 0 == Message.count(m1,dummy_other,:add)
    assert 0 == Message.count(m1,dummy_other,:get)

    assert 0 == Message.count(m2,dummy_me,:add)
    assert 0 == Message.count(m2,dummy_me,:get)
    assert 0 == Message.count(m2,dummy_other,:add)
    assert 1 == Message.count(m2,dummy_other,:get)

    assert 1 == Message.count(m12,dummy_me,:add)
    assert 0 == Message.count(m12,dummy_me,:get)
    assert 0 == Message.count(m12,dummy_other,:add)
    assert 1 == Message.count(m12,dummy_other,:get)
  end

  test "topology() returns the list of NetIDs" do
    timed_item1 = Item.new(dummy_me)    |> Item.op(:add) |> TimedItem.construct(LocalClock.new(dummy_me))
    timed_item2 = Item.new(dummy_other) |> Item.op(:get) |> TimedItem.construct(LocalClock.new(dummy_other))

    m1 = Message.new("hello") |> Message.add(timed_item1)
    m2 = Message.new("hello") |> Message.add(timed_item2)
    m12 = Message.merge(m1,m2)

    assert [timed_item1] == Message.topology(m1)
    assert [timed_item2] == Message.topology(m2)
    assert [timed_item1, timed_item2] == Message.topology(m12) |> Enum.sort
  end

  # extract_netids
  test "extract_netids() raises on invalid input" do
    assert_raise FunctionClauseError, fn -> Message.extract_netids(:ok) end
    assert_raise FunctionClauseError, fn -> Message.extract_netids([]) end
    assert_raise FunctionClauseError, fn -> Message.extract_netids({}) end
    assert_raise FunctionClauseError, fn -> Message.extract_netids(nil) end
  end

  test "extract_netids() returns empty list for empty message" do
    m = Message.new("hello")
    assert [] = Message.extract_netids(m)
  end

  test "extract_netids() returns added items" do
    ni1 = dummy_me
    ni2 = dummy_other
    timed_item1 = Item.new(ni1)  |> TimedItem.construct(LocalClock.new(ni1))
    timed_item2 = Item.new(ni2) |> TimedItem.construct(LocalClock.new(ni2))
    m = Message.new("hello") |> Message.add(timed_item1) |> Message.add(timed_item2)
    assert [ni1] == m |> Message.extract_netids |> Enum.filter(fn(x) -> x == ni1 end)
    assert [ni2] == m |> Message.extract_netids |> Enum.filter(fn(x) -> x == ni2 end)
  end

  test "encode_with() raises on invalid input" do
    assert_raise FunctionClauseError, fn -> Message.encode_with(:ok, %{}) end
    assert_raise FunctionClauseError, fn -> Message.encode_with([], %{}) end
    assert_raise FunctionClauseError, fn -> Message.encode_with({}, %{}) end
    assert_raise FunctionClauseError, fn -> Message.encode_with(nil, %{}) end
  end

  test "encode_with() works with decode_with" do
    ni1 = dummy_me
    ni2 = dummy_other
    timed_item1 = Item.new(ni1)  |> TimedItem.construct(LocalClock.new(ni1))
    timed_item2 = Item.new(ni2) |> TimedItem.construct(LocalClock.new(ni2))
    m = Message.new("hello") |> Message.add(timed_item1) |> Message.add(timed_item2)

    ids = Message.extract_netids(m) |> Enum.uniq
    {_count, fwd, rev} = ids |> Enum.reduce({0, %{}, %{}}, fn(x,acc) ->
      {count, fw, re} = acc
      {count+1, Map.put(fw, x, count), Map.put(re, count, x)}
    end)

    encoded = Message.encode_with(m, fwd)
    {decoded, <<>>} = Message.decode_with(encoded, rev)

    assert decoded == m

    # check decode_with raises on bad input
    assert_raise KeyError, fn -> Message.decode_with(encoded, %{}) end
    assert_raise FunctionClauseError, fn -> Message.decode_with(encoded, %{0 => 0}) end
  end
end
