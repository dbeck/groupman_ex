defmodule GroupManager.Chatter.PeerData do
  
  require Record
  require GroupManager.Chatter.NetID
  require GroupManager.Chatter.BroadcastID
  alias GroupManager.Chatter.NetID
  alias GroupManager.Chatter.BroadcastID
  
  Record.defrecord :peer_data,
                   id: nil,
                   broadcast_seqno: 0,
                   seen_ids: [],
                   inbound_pid: nil,
                   outbound_pid: nil

  @type t :: record( :peer_data,
                     id: NetID.t,
                     broadcast_seqno: integer,
                     seen_ids: list(BroadcastID.t),
                     inbound_pid: pid | nil,
                     outbound_pid: pid | nil )
  
  @spec new(NetID.t) :: t
  def new(id)
  when NetID.is_valid(id)
  do
    peer_data(id: id)
  end
  
  defmacro is_valid(data) do
    case Macro.Env.in_guard?(__CALLER__) do
      true ->
        quote do
          is_tuple(unquote(data)) and tuple_size(unquote(data)) == 6 and
          :erlang.element(1, unquote(data)) == :peer_data and
          # id
          NetID.is_valid(:erlang.element(2, unquote(data))) and
          # broadcast_seqno
          is_integer(:erlang.element(3, unquote(data))) and
          :erlang.element(3, unquote(data)) >= 0 and
          # seen ids
          is_list(:erlang.element(4, unquote(data))) and
          # inbound pid
          (:erlang.element(5, unquote(data)) == nil or
           is_pid(:erlang.element(5, unquote(data)))) and
          # outbound pid
          (:erlang.element(6, unquote(data)) == nil or
           is_pid(:erlang.element(6, unquote(data))))
        end
      false ->
        quote bind_quoted: [result: data] do
          is_tuple(result) and tuple_size(result) == 6 and
          :erlang.element(1, result) == :peer_data and
          # id
          NetID.is_valid(:erlang.element(2, data)) and
          # broadcast_seqno
          is_integer(:erlang.element(3, data)) and
          :erlang.element(3, data) >= 0 and
          # seen ids
          is_list(:erlang.element(4, data)) and
          # inbound pid
          (:erlang.element(5, data) == nil or
           is_pid(:erlang.element(5, data))) and
          # outbound pid
          (:erlang.element(6, data) == nil or
           is_pid(:erlang.element(6, data)))
        end
    end
  end
  
  @spec valid?(t) :: boolean
  def valid?(data)
  when is_valid(data)
  do
    true
  end
  
  def valid?(_), do: false

  @spec id(t) :: NetID.t
  def id(d)
  when is_valid(d)
  do
    peer_data(d, :id)
  end
  
  @spec broadcast_seqno(t) :: integer
  def broadcast_seqno(d)
  when is_valid(d)
  do
    peer_data(d, :broadcast_seqno)
  end
  
  @spec broadcast_seqno(t, integer) :: t
  def broadcast_seqno(d, v)
  when is_valid(d) and is_integer(v) and v >= 0
  do
    peer_data(d, broadcast_seqno: v)
  end
  
  @spec max_broadcast_seqno(t, integer) :: t
  def max_broadcast_seqno(d, v)
  when is_valid(d) and is_integer(v) and v >= 0
  do
    peer_data(d, broadcast_seqno: max(v, peer_data(d, :broadcast_seqno)))
  end
  
  @spec seen_ids(t) :: list(BroadcastID.t)
  def seen_ids(d)
  when is_valid(d)
  do
    peer_data(d, :seen_ids)
  end
  
  @spec merge_seen_ids(t, list(BroadcastID.t)) :: t
  def merge_seen_ids(d, []), do: d
  
  def merge_seen_ids(d, ids)
  when is_valid(d) and is_list(ids)
  do
    old_ids = peer_data(d, :seen_ids)
    peer_data(d, seen_ids: BroadcastID.merge_lists(old_ids, ids))
  end
end