defmodule MeansEnd.Connection do
  use GenServer

  require Logger

  defstruct [:socket, :prices, buffer: <<>>]

  @spec start_link(:gen_tcp.socket()) :: GenServer.on_start()
  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  @impl GenServer
  def init(socket) do
    table = :ets.new(:prices, [:ordered_set])
    state = %__MODULE__{socket: socket, prices: table}
    {:ok, state}
  end

  @impl true
  def handle_info(message, state)

  def handle_info({:tcp, socket, data}, %__MODULE__{socket: socket} = state) do
    :ok = :inet.setopts(socket, active: :once)

    update_in(state.buffer, &(&1 <> data))
    |> handle_new_data()
  end

  def handle_info({:tcp_closed, socket}, %__MODULE__{socket: socket} = state) do
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, socket, reason}, %__MODULE__{socket: socket} = state) do
    Logger.error("TCP connection error: #{inspect(reason)}")
    {:stop, :normal, state}
  end

  defp handle_new_data(
         %__MODULE__{
           buffer: <<?I, timestamp::big-signed-32, price::big-signed-32, rest::binary>>
         } = state
       ) do
    :ets.insert(state.prices, {timestamp, price})
    handle_new_data(%__MODULE__{state | buffer: rest})
  end

  defp handle_new_data(
         %__MODULE__{
           buffer: <<?Q, mintime::big-signed-32, maxtime::big-signed-32, rest::binary>>
         } = state
       ) do
    select = [
      {{:"$1", :"$2"}, [{:andalso, {:"=<", mintime, :"$1"}, {:"=<", :"$1", maxtime}}], [:"$2"]}
    ]

    prices = :ets.select(state.prices, select)

    :ok = :gen_tcp.send(state.socket, <<mean(prices)::big-signed-32>>)
    handle_new_data(%__MODULE__{state | buffer: rest})
  end

  defp handle_new_data(%__MODULE__{} = state) do
    {:noreply, state}
  end

  defp mean([]), do: 0

  defp mean([_ | _] = data) do
    data
    |> Enum.sum()
    |> Kernel./(length(data))
    |> trunc()
  end
end
