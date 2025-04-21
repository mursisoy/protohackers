defmodule BudgetChat.Connection do
  use GenServer, restart: :temporary

  alias BudgetChat.{BroadcastRegistry, UsernameRegistry}

  require Logger

  @spec start_link(:gen_tcp.socket()) :: GenServer.on_start()
  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  defstruct [:socket, :username, buffer: <<>>]

  @impl GenServer
  def init(socket) do
    send(self(), :greetings)
    {:ok, %__MODULE__{socket: socket}}
  end

  @impl GenServer
  def handle_info(message, state)

  def handle_info(
        {:tcp, socket, data},
        %__MODULE__{socket: socket} = state
      ) do
    state = update_in(state.buffer, &(&1 <> data))
    :ok = :inet.setopts(socket, active: :once)
    handle_new_data(state)
  end

  def handle_info(
        {:tcp_closed, socket},
        %__MODULE__{socket: socket, username: nil} = state
      ) do
    {:stop, :normal, state}
  end

  def handle_info(
        {:tcp_closed, socket},
        %__MODULE__{socket: socket, username: username} = state
      ) do
    chat_send("* #{username} has left the room")
    {:stop, :normal, state}
  end

  def handle_info(
        {:tcp_error, socket, reason},
        %__MODULE__{socket: socket} = state
      ) do
    Logger.error("TCP connection error: #{inspect(reason)}")
    {:stop, :normal, state}
  end

  def handle_info(:greetings, state) do
    :ok = :gen_tcp.send(state.socket, "who?\n")
    {:noreply, state}
  end

  def handle_info({:broadcast, message}, state) do
    :ok = :gen_tcp.send(state.socket, message <> "\n")
    {:noreply, state}
  end

  @spec handle_new_data(t()) :: {:noreply, t()} | {:stop, :normal, t()}
  defp handle_new_data(%__MODULE__{buffer: buffer} = state) do
    case String.split(buffer, ["\r\n", "\n"], parts: 2) do
      [line, rest] ->
        new_state = %__MODULE__{state | buffer: rest}
        process_message(line, new_state)

      _ ->
        {:noreply, state}
    end
  end

  @spec process_message(String.t(), t()) :: {:noreply, t()} | {:stop, :normal, t()}
  defp process_message(username, %__MODULE__{username: nil} = state) do
    with {:validation, true} <- {:validation, valid_username?(username)},
         {:ok, _} <- Registry.register(UsernameRegistry, username, :no_value) do
      room_users =
        Registry.lookup(BroadcastRegistry, :broadcast)
        |> Enum.map_join(", ", fn {_, value} -> value end)

      {:ok, _} = Registry.register(BroadcastRegistry, :broadcast, username)
      :ok = :gen_tcp.send(state.socket, "* The room contains: #{room_users}\n")
      chat_send("* #{username} has entered the room")
      handle_new_data(put_in(state.username, username))
    else
      {:validation, false} ->
        :gen_tcp.send(state.socket, "Not a valid username\n")
        {:stop, :normal, %__MODULE__{state | buffer: <<>>}}

      {:error, {:already_registered, _}} ->
        :gen_tcp.send(state.socket, "Username already in use\n")
        {:stop, :normal, %__MODULE__{state | buffer: <<>>}}
    end
  end

  defp process_message(message, state) do
    chat_send("[#{state.username}] #{message}")
    handle_new_data(state)
  end

  @spec chat_send(binary()) :: :ok
  defp chat_send(message) do
    sender = self()

    Registry.dispatch(BroadcastRegistry, :broadcast, fn entries ->
      Enum.each(entries, fn {pid, _value} ->
        if pid != sender do
          send(pid, {:broadcast, message})
        end
      end)
    end)
  end

  @spec valid_username?(binary()) :: boolean()
  defp valid_username?(username) do
    String.match?(username, ~r/^[a-zA-Z0-9_]+$/)
  end
end
