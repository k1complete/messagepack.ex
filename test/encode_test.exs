Code.require_file "../test_helper", __FILE__

defmodule EncodeTest do
  use ExUnit.Case
  import MessagePack
  test :u_int7 do
    lc i inlist :lists.seq(0,127) do
      assert {i, ""} == decode1(encode(i))
    end
  end
  test :neg_int5 do
    lc i inlist :lists.seq(-32,-1) do
      assert {i, ""} == decode1(encode(i))
    end
  end
  test :u_int8 do
    lc i inlist [0,1,126,127,128,129,254,255] do
      assert {i, ""} == decode1(encode(i))
    end
  end
  test :u_int16 do
    lc i inlist [0,1,254,255,256,257,65534,65535] do
      assert {i, ""} == decode1(encode(i))
    end
  end
  test :u_int32 do
    lc i inlist :lists.seq(0xfffffff0, 0xffffffff) do
      assert {i, ""} == decode1(encode(i))
    end
  end
end

defmodule BinTestmmm do
  use ExUnit.Case
  import MessagePack
  test :bin5 do
    i = "12345678901234567890"
    assert {i, ""} == decode1(encode(i))
  end
  test :bin16 do
    i = "123451000000000000000000000000000000000000000000000000000"
    assert {i, ""} == decode1(encode(i))
  end
  test :list4 do
    i = :lists.seq(0,15)
    assert {i, ""} == decode1(encode(i))
  end
  test :list16 do
    i = :lists.seq(0,65535)
    assert {i, ""} == decode1(encode(i))
  end
  test :list32 do
    i = :lists.seq(0,65536)
    assert {i, ""} == decode1(encode(i))
  end
  test :map4 do
    i = [{"a", 1}, {"ab", 2}, {"abc", 3}]
    assert {i, ""} == decode1(encode(i))
  end
  test :map16 do
    i = lc j inlist :lists.seq(0, 257), do: {"#{j}", j}
    assert {i, ""} == decode1(encode(i))
  end
  test :map32 do
    i = lc j inlist :lists.seq(0, 65537), do: {"#{j}", j}
    assert {i, ""} == decode1(encode(i))
  end
end
