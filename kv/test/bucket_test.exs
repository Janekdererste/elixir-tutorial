defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, bucket} = KV.Bucket.start_link([])
    %{bucket: bucket}
  end

  test "store values by key", %{bucket: bucket} do
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end

  test "delete values by key", %{bucket: bucket} do

    key = "some-key"
    value = "some-value"

    # set up state
    assert KV.Bucket.get(bucket, key) == nil
    KV.Bucket.put(bucket, key, value)
    assert KV.Bucket.get(bucket, key) == value

    # act
    storedValue = KV.Bucket.delete(bucket, key)

    # assert
    assert KV.Bucket.get(bucket, key) == nil
    assert storedValue == value
  end
end