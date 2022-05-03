defmodule KV.Registry do
  use GenServer

  ## Client api goes here
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  def lookup(server, name) do
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  ## GenServer callbacks

  @impl true
  def init(table) do
    names = :ets.new(table, [:named_table, read_concurrency: true])
    refs = %{}
    {:ok, {names, refs}}
  end

  @impl true
  def handle_call({:create, name}, _from, state) do
    {names, refs} = state
    lookup_result = lookup(names, name)

    case lookup_result do
      # if the lookup result is :ok, the name is already in the table
      {:ok, pid} ->
        {:reply, pid, {names, refs}}

      # if the result is :error, the name must be put into the table and a new bucket must be created
      :error ->
        {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, pid})
        {:reply, pid, {names, refs}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    references = elem(state, 1)
    names = elem(state, 0)
    {name, refs} = Map.pop(references, ref)
    names = :ets.delete(names, name)
    {:noreply, {names, refs}}
  end

  @doc """
  This seems to be the default handler for everything that can't be digested
  """
  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in KV.Registry: #{inspect(msg)}")
    {:noreply, state}
  end
end
