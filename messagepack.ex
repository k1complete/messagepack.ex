defmodule MessagePack do
  def encode(i) when is_integer(i) and i >= 0 and i <= 127, do: <<0|1,i|7>>
  def encode(i) when is_integer(i) and i >= -32 and i <= -1, do:  <<0b111|3,i|5>>
  def encode(i) when is_integer(i) and i >= 0 and i <= 0x0ff, do:  <<0xcc|8,i|8>>
  def encode(i) when is_integer(i) and i >= 0 and i <= 0x0ffff, do: <<0xcd|8, i|16>>
  def encode(i) when is_integer(i) and i >= 0 and i <= 0x0ffffffff, do: <<0xce|8, i|32>>
  def encode(i) when is_integer(i) and i >= 0 and i <= 0x0ffffffffffff,  do: <<0xcf|8, i|64>>
  def encode(i) when i == nil, do: <<0xc0>>
  def encode(i) when is_boolean(i) and i == true, do: <<0xc3>>
  def encode(i) when is_boolean(i) and i == false, do: <<0xc2>>
  def encode(i) when is_binary(i) and size(i) <= 31, do: <<0b101|3, size(i)|5>> <> i
  def encode(i) when is_binary(i) and size(i) <= 0x0ffff, do: <<0xda|8, size(i)|16>> <> i
  def encode(i) when is_binary(i) and size(i) <= 0x0ffffffff, do: <<0xdb|8, size(i)|32>> <> i
  def encode(i) when is_list(i) do
   if (length(Keyword.keys(i)) == length(i)) do
      encode_kv(i)
    else
      encode_list(i)
    end
  end
  def encode_list(i) when is_list(i) and length(i) <= 15 do
    <<0b1001|4, length(i)|4>> <> list_to_binary(Enum.map i, fn(n) -> encode(n) end)
  end
  def encode_list(i) when is_list(i) and length(i) <= 0x0ffff do
    <<0xdc|8, length(i)|16>> <> list_to_binary(Enum.map i, fn(n) -> encode(n) end)
  end
  def encode_list(i) when is_list(i) and length(i) <= 0x0ffffffff do
    <<0xdd|8, length(i)|32>> <> list_to_binary(Enum.map i, fn(n) -> encode(n) end)
  end
  def encode_kv(i) when length(i) <= 15 do
    <<0b1000|4, length(i)|4>> <> list_to_binary(Enum.map i, fn({k,v}) -> encode(k) <> encode(v) end)
  end
  def encode_kv(i) when length(i) <= 0x0ffff do
    <<0xde|8, length(i)|16>> <> list_to_binary(Enum.map i, fn({k,v}) -> encode(k) <> encode(v) end)
  end
  def encode_kv(i) when length(i) <= 0x0ffffffff do
    <<0xdf|8, length(i)|32>> <> list_to_binary(Enum.map i, fn({k,v}) -> encode(k) <> encode(v) end)
  end
  def decode1("") do
    []
  end
  def decode1(<<0b0|1,i|7,t|:binary>>) do
    {i, t}
  end
  def decode1(<<0b111|3,i|5,t|:binary>>) do
    {-i, t}
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
  def decode1(<<0xda|8, n|8, t|:binary>>) do
    len = size(t)
    {Erlang.binary.part(t, 0, n), Erlang.binary.part(t, len, n - len)}
  end
  def decode1(<<0xdb|8, n|8, t|:binary>>) do
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
end
