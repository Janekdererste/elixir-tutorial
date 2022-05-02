defmodule KV.Bucket do
  use Agent, restart: :temporary

  @doc """
  Start a new bucket.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  get the value from the bucket by key
  """
  def get(bucket, key) do
    Agent.get(bucket, fn state -> Map.get(state, key) end)
  end

  @doc """
  puts the value for the given key into the bucket
  """
  def put(bucket, key, value) do
    Agent.update(bucket, fn state -> Map.put(state, key, value) end)
  end

  def delete(bucket, key) do
    Agent.get_and_update(bucket, fn state ->
      Map.pop(state, key)
    end)
  end
end
