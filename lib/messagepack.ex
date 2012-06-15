
defmodule MessagePack.Macro do
  import Bitwise
  defmacro defencode_int(bit, prefix, prefixbit) do
    quote do
      def encode(i) when is_integer(i) and i >= 0 and i < bsl(1, unquote(bit)) do
	<< unquote(prefix) | unquote(prefixbit), i | unquote(bit) >>
      end
    end
  end
  defmacro defencode_bin(bit, prefix, prefixbit) do
    quote do
      def encode(i) when is_binary(i) and size(i) < bsl(1, unquote(bit)) do
	<< unquote(prefix) | unquote(prefixbit), size(i) | unquote(bit) >> <> i
      end
    end
  end
  defmacro defencode_list(bit, prefix, prefixbit) do
    quote do
      defp encode_list(i) when is_list(i) and length(i) < bsl(1, unquote(bit)) do
	<< unquote(prefix) | unquote(prefixbit), length(i) | unquote(bit) >> <>
	  list_to_binary(Enum.map i, fn(n) -> encode(n) end)
      end
    end
  end
  defmacro defencode_kv(bit, prefix, prefixbit) do
    quote do
      defp encode_kv(i) when length(i) < bsl(1, unquote(bit)) do
	<< unquote(prefix) | unquote(prefixbit), length(i) | unquote(bit) >> <>
	  list_to_binary(Enum.map i, fn({k, v}) -> encode(k) <> encode(v) end)
      end
    end
  end
end
defmodule MessagePack do
  import Bitwise
  import MessagePack.Macro
  defencode_int(7, 0, 1)
  defencode_int(8, 0xcc, 8)
  defencode_int(16, 0xcd, 8)
  defencode_int(32, 0xce, 8)
  defencode_int(64, 0xcf, 8)
  def encode(i) when is_integer(i) and i >= -32 and i <= -1, do:  <<0b111|3,i|5>>
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
  def decode1(<<0b0|1,i|7,t|:binary>>) do
    {i, t}
  end
  def decode1(<<0b111|3,i|5,t|:binary>>) do
    {i - 32, t}
  end
  def decode1(<<0xcc, i|8, t|:binary>>) do
    {i, t}
  end
  def decode1(<<0xcd, i|16, t|:binary>>) do
    {i, t}
  end
  def decode1(<<0xce, i|32, t|:binary>>) do
    {i, t}
  end
  def decode1(<<0xcf, i|64, t|:binary>>) do
    {i, t}
  end
  def decode1(<<0xc0, t|:binary>>) do
    {nil, t}
  end
  def decode1(<<0xc3, t|:binary>>) do
    {true, t}
  end
  def decode1(<<0xc2, t|:binary>>) do
    {false, t}
  end
  def decode1(<<0b101|3,n|5, t|:binary>>) do
    len = size(t)
    {Erlang.binary.part(t, 0, n), Erlang.binary.part(t, len, n - len)}
  end
  def decode1(<<0xda|8, n|16, t|:binary>>) do
    len = size(t)
    {Erlang.binary.part(t, 0, n), Erlang.binary.part(t, len, n - len)}
  end
  def decode1(<<0xdb|8, n|32, t|:binary>>) do
    len = size(t)
    {Erlang.binary.part(t, 0, n), Erlang.binary.part(t, len, n - len)}
  end
  def decode1(<<0b1001|4, len|4, t|:binary>>) do
    loop len, t, [] do
      0, t, a -> {Erlang.lists.reverse(a), t}
      n, t, a -> 
	{d1, b1} = decode1(t)
	recur n-1, b1, [d1|a]
    end
  end
  def decode1(<<0xdc|8, len|16, t|:binary>>) do
    loop len, t, [] do
      0, t, a -> {Erlang.lists.reverse(a), t}
      n, t, a -> 
	{d1, b1} = decode1(t)
	recur n-1, b1, [d1|a]
    end
  end
  def decode1(<<0xdd|8, len|32, t|:binary>>) do
    loop len, t, [] do
      0, t, a -> {Erlang.lists.reverse(a), t}
      n, t, a -> 
	{d1, b1} = decode1(t)
	recur n-1, b1, [d1|a]
    end
  end
  def decode1(<<0b1000|4, len|4, t|:binary>>) do
    loop len, t, [] do
      0, t, a -> {Erlang.lists.reverse(a), t}
      n, t, a ->
	{k1, ret1} = decode1(t)
	{v1, ret2} = decode1(ret1)
	recur n - 1, ret2, [{k1, v1}| a]
    end
  end
  def decode1(<<0xde|8, len|16, t|:binary>>) do
    loop len, t, [] do
      0, t, a -> {Erlang.lists.reverse(a), t}
      n, t, a ->
	{k1, ret1} = decode1(t)
	{v1, ret2} = decode1(ret1)
	recur n - 1, ret2, [{k1, v1}| a]
    end
  end
  def decode1(<<0xdf|8, len|32, t|:binary>>) do
    loop len, t, [] do
      0, t, a -> {Erlang.lists.reverse(a), t}
      n, t, a ->
	{k1, ret1} = decode1(t)
	{v1, ret2} = decode1(ret1)
	recur n - 1, ret2, [{k1, v1}| a]
    end
  end
end
