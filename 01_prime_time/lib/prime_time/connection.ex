defmodule PrimeTime.Connection do
  use GenServer

  require Logger

  defstruct [:socket, buffer: <<>>]

  @spec start_link(:gen_tcp.socket()) :: GenServer.on_start()
  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  @impl GenServer
  def init(socket) do
    state = %__MODULE__{socket: socket}
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

  defp handle_new_data(%__MODULE__{buffer: buffer} = state) do
    case String.split(buffer, "\n", parts: 2) do
      [line, rest] ->
        process_line(line, state, rest)

      _ ->
        {:noreply, state}
    end
  end

  defp process_line(line, %__MODULE__{} = state, rest) do
    with {:ok, %{"method" => "isPrime", "number" => number}} when is_number(number) <-
           Jason.decode(line) do
      Logger.info("Received data: #{inspect(line)}")

      response =
        %{"method" => "isPrime", "prime" => prime?(number)}
        |> Jason.encode!()
        |> Kernel.<>("\n")
        |> IO.inspect()

      :ok = :gen_tcp.send(state.socket, response)

      new_state = %__MODULE__{state | buffer: rest}
      handle_new_data(new_state)
    else
      _ ->
        :gen_tcp.send(state.socket, "\n")
        Logger.error("Failed to decode JSON or invalid data: #{inspect(line)}")
        {:stop, :normal, %__MODULE__{state | buffer: <<>>}}
    end
  end

  defp prime?(n) when is_float(n), do: false
  defp prime?(n) when n <= 1, do: false
  defp prime?(n) when n in [2, 3], do: true

  defp prime?(n) do
    floored_sqrt =
      :math.sqrt(n)
      |> Float.floor()
      |> round

    !Enum.any?(2..floored_sqrt, &(rem(n, &1) == 0))
  end
end
