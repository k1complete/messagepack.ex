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
    lc i inlist :lists.seq(0, 255) do
      assert {i, ""} == decode1(encode(i))
    end
  end
  test :u_int16 do
    lc i inlist :lists.seq(0, 0xffff) do
      assert {i, ""} == decode1(encode(i))
    end
  end
  test :u_int32 do
    lc i inlist :lists.seq(0xfffffff0, 0xffffffff) do
      assert {i, ""} == decode1(encode(i))
    end
  end
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
    i = [{"a", 1}, {"ab", 2}, {"abc", 3},
         {"b", 1}, {"bb", 2}, {"bbc", 3},
         {"c", 1}, {"cbb", 2}, {"cbbc", 3},
         {"d", 1}, {"dbb", 2}, {"dbbc", 3},
         {"e", 1}, {"ebb", 2}, {"ebbc", 3},
         {"f", 1}, {"fbb", 2}, {"fbbc", 3}]
    assert {i, ""} == decode1(encode(i))
  end
end
