defmodule MessagePack do
  def encode(i) when is_integer(i) and i >= 0 and i <= 127 do
    <<0|1,i|7>>
  end
  def encode(i) when is_integer(i) and i >= -32 and i <= -1 do
    <<3|1,i|5>>
  end
  def encode(i) when is_integer(i) and i >= 0 and <= 0x0ff do
    <<0xcc|8,i|8>>
  end
  def encode(i) when is_integer(i) and i >= 0 and <= 0x0ffff do
    <<0xcd|8, i|16>>
  end
  def encode(i) when is_integer(i) and i >= 0 and <= 0x0ffffffff do
    <<0xce|8, i|32>>
  end
  def encode(i) when is_integer(i) and i >= 0 and <= 0x0ffffffffffff do
    <<0xcf|8, i|64>>
  end
  def encode(i) when !(is_boolean(i) or i) do
    <<0xc0>>
  end
  def encode(i) when is_boolean(i) and t do
    <<0xc3>>
  end
end
  
  