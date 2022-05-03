defmodule KV.RegistryTest do
  use ExUnit.Case, async: false

  setup context do
    _ = start_supervised!({KV.Registry, name: context.test})
    %{registry: context.test}
  end

  test "spawn buckets", %{registry: registry} do
    assert KV.Registry.lookup(registry, "shopping") == :error

    KV.Registry.create(registry, "shopping")
    assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    KV.Bucket.put(bucket, "milk", 1)
    assert KV.Bucket.get(bucket, "milk") == 1
  end

  test "removes buckets on exit", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
    Agent.stop(bucket)

    # make a synchronus call to ensure, the DOWN message was processed
    _ = KV.Registry.create(registry, "bogus")

    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  test "removes bucket on crash", %{registry: registry} do
    KV.Registry.create(registry, "name")
    {:ok, bucket} = KV.Registry.lookup(registry, "name")

    # stop the agent forcefully with a bad exit code
    Agent.stop(bucket, :shutdown)

    # make a synchronus call to ensure, the DOWN message was processed
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "name") == :error
  end
end
