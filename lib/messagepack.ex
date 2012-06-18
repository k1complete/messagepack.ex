
defmodule MessagePack.Macro do
  import Bitwise
  def build_fix(bit, prefix, prefixbit, [guard: g]) do
    quote do
      def encode(i) when unquote(g) do
	<< unquote(prefix) | unquote(prefixbit), i | unquote(bit) >>
      end
    end
  end
  def build_tlv(bit, prefix, prefixbit, [guard: g, size: s, tail: t, name: n]) do
    quote do
      def unquote(n).(i) when unquote(g) do
	<< unquote(prefix) | unquote(prefixbit), unquote(s) | unquote(bit) >> <> unquote(t)
      end
    end
  end
  def build_tlv(bit, prefix, prefixbit, [guard: g, size: s, tail: t]) do
    build_tlv(bit, prefix, prefixbit, [guard: g, size: s, tail: t, name: :encode])
  end
  defmacro defencode_int(bit, prefix, prefixbit) do
    min = - bsl(1, bit-1) + 1
    max =   bsl(1, bit-1)
    g = quote do: is_integer(i) and unquote(min) <= i and i < unquote(max) 
    build_fix(bit, prefix, prefixbit, [guard: g])
  end
  defmacro defencode_uint(bit, prefix, prefixbit) do
    g = quote do: is_integer(i) and i >= 0 and i < bsl(1, unquote(bit))
    build_fix(bit, prefix, prefixbit, [guard: g])
  end
  defmacro defencode_bin(bit, prefix, prefixbit) do
    g = quote do: is_binary(i) and size(i) < bsl(1, unquote(bit))
    t = quote do: i
    s = quote do: size(i)
    build_tlv(bit, prefix, prefixbit, [guard: g, size: s, tail: t])
  end
  defmacro defencode_list(bit, prefix, prefixbit) do
    g = quote do: is_list(i) and length(i) < bsl(1, unquote(bit))
    t = quote do: list_to_binary(Enum.map i, fn(n) -> encode(n) end)
    s = quote do: length(i)
    build_tlv(bit, prefix, prefixbit, [guard: g, size: s, tail: t, name: :encode_list])
  end
  defmacro defencode_kv(bit, prefix, prefixbit) do
    g = quote do: is_list(i) and length(i) < bsl(1, unquote(bit))
    t = quote do: list_to_binary(Enum.map i, fn({k,v}) -> encode(k) <> encode(v) end)
    s = quote do: length(i)
    build_tlv(bit, prefix, prefixbit, [guard: g, size: s, tail: t, name: :encode_kv])
  end
  defmacro defdecode_int(bit, prefix, prefixbit) do
    quote do
      def decode1(<<unquote(prefix)|unquote(prefixbit), i|unquote(bit),t|:binary>>) do
	th = bsl(1, unquote(bit) - 1)
	max = bsl(1, unquote(bit))
	ret = if (th <= i), do: i-max, else: i
	{ret, t}
      end
    end
  end
  defmacro defdecode_uint(bit, prefix, prefixbit) do
    quote do
      def decode1(<<unquote(prefix)|unquote(prefixbit), i|unquote(bit),t|:binary>>) do
	{i, t}
      end
    end
  end
  defmacro defdecode_bin(bit, prefix, prefixbit) do
    quote do
      def decode1(<<unquote(prefix)|unquote(prefixbit), n|unquote(bit), t|:binary>>) do
	len = size(t)
	{:binary.part(t, 0, n), :binary.part(t, len, n - len)}
      end
    end
  end
  defmacro defdecode_list(bit, prefix, prefixbit) do
    quote do
      def decode1(<<unquote(prefix)|unquote(prefixbit), len|unquote(bit), t|:binary>>) do
	loop len, t, [] do
	  0, t, a -> {:lists.reverse(a), t}
	  n, t, a -> 
	    {d1, b1} = decode1(t)
	    recur n - 1, b1, [d1 | a]
	end
      end
    end
  end
  defmacro defdecode_map(bit, prefix, prefixbit) do
    quote do
      def decode1(<<unquote(prefix) | unquote(prefixbit), len|unquote(bit), t|:binary>>) do
	loop len, t, [] do
	  0, t, a -> {:lists.reverse(a), t}
	  n, t, a ->
	    {k1, ret1} = decode1(t)
	    {v1, ret2} = decode1(ret1)
	    recur n - 1, ret2, [{k1, v1}|a]
	end
      end
    end
  end
end

defmodule MessagePack do
  import Bitwise
  import MessagePack.Macro
  defencode_uint(7, 0, 1)
  def encode(i) when is_integer(i) and i >= -32 and i <= -1, do:  <<0b111|3,i|5>>
  defencode_int(8, 0xd0, 8)
  defencode_int(16, 0xd1, 8)
  defencode_int(32, 0xd2, 8)
  defencode_int(64, 0xd3, 8)

  defencode_uint(8, 0xcc, 8)
  defencode_uint(16, 0xcd, 8)
  defencode_uint(32, 0xce, 8)
  defencode_uint(64, 0xcf, 8)
  def encode(i) when i == nil, do: <<0xc0>>
  def encode(i) when is_boolean(i) and i == true, do: <<0xc3>>
  def encode(i) when is_boolean(i) and i == false, do: <<0xc2>>
  defencode_bin(5, 0b101, 3)
  defencode_bin(16, 0xda, 8)
  defencode_bin(32, 0xdb, 8)
  def encode(i) when is_list(i) do
   if (length(Keyword.keys(i)) == length(i)) do
      encode_kv(i)
    else
      encode_list(i)
    end
  end
  defencode_list(4, 0b1001, 4)
  defencode_list(16, 0xdc, 8)
  defencode_list(32, 0xdd, 8)
  defencode_kv(4, 0b1000, 4)
  defencode_kv(16, 0xde, 8)
  defencode_kv(32, 0xdf, 8)
  def decode1("") do
    []
  end
  defdecode_uint(7, 0b0, 1)
  defdecode_int(8, 0xd0, 8)
  defdecode_int(16, 0xd1, 8)
  defdecode_int(32, 0xd2, 8)
  defdecode_int(64, 0xd3, 8)
  defdecode_uint(8, 0xcc, 8)
  defdecode_uint(16, 0xcd, 8)
  defdecode_uint(32, 0xce, 8)
  defdecode_uint(64, 0xcf, 8)
  def decode1(<<0b111|3,i|5,t|:binary>>), do: {i - 32, t}
  def decode1(<<0xc0, t|:binary>>), do: {nil, t}
  def decode1(<<0xc3, t|:binary>>), do: {true, t}
  def decode1(<<0xc2, t|:binary>>), do: {false, t}
  defdecode_bin(5, 0b101, 3)
  defdecode_bin(16, 0xda, 8)
  defdecode_bin(32, 0xdb, 8)
  defdecode_list(4, 0b1001, 4)
  defdecode_list(16, 0xdc, 8)
  defdecode_list(32, 0xdd, 8)
  defdecode_map(4, 0b1000, 4)
  defdecode_map(16, 0xde, 8)
  defdecode_map(32, 0xdf, 8)
end
