defmodule Mob.Connection do
  use GenServer, restart: :temporary

  require Logger

  @spec start_link(:gen_tcp.socket()) :: GenServer.on_start()
  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  @type t() :: %__MODULE__{
          downstream_socket: :gen_tcp.socket(),
          upstream_socket: :gen_tcp.socket(),
          downstream_buffer: binary(),
          upstream_buffer: binary()
        }

  defstruct [
    :downstream_socket,
    :upstream_socket,
    downstream_buffer: <<>>,
    upstream_buffer: <<>>
  ]

  @impl GenServer
  def init(socket) do
    [host, port] =
      :mob
      |> Application.fetch_env!(:upstream_server)
      |> String.split(":", parts: 2)

    {:ok, upstream_socket} =
      :gen_tcp.connect(to_charlist(host), String.to_integer(port), [
        :binary,
        active: true,
        packet: 0
      ])

    {:ok, %__MODULE__{downstream_socket: socket, upstream_socket: upstream_socket}}
  end

  @impl GenServer
  def handle_info(message, state)

  def handle_info(
        {:tcp, socket, data},
        %__MODULE__{downstream_socket: socket} = state
      ) do
    state = update_in(state.downstream_buffer, &(&1 <> data))
    :ok = :inet.setopts(socket, active: :once)
    handle_new_data(socket, state)
  end

  def handle_info(
        {:tcp, socket, data},
        %__MODULE__{upstream_socket: socket} = state
      ) do
    state = update_in(state.upstream_buffer, &(&1 <> data))
    :ok = :inet.setopts(socket, active: :once)
    handle_new_data(socket, state)
  end

  def handle_info(
        {:tcp_closed, socket},
        %__MODULE__{
          downstream_socket: socket,
          upstream_socket: upstream_socket
        } = state
      ) do
    :gen_tcp.close(upstream_socket)
    {:stop, :normal, state}
  end

  def handle_info(
        {:tcp_closed, socket},
        %__MODULE__{
          downstream_socket: downstream_socket,
          upstream_socket: socket
        } = state
      ) do
    :gen_tcp.close(downstream_socket)
    {:stop, :normal, state}
  end

  def handle_info(
        {:tcp_error, socket, reason},
        %__MODULE__{downstream_socket: socket, upstream_socket: upstream_socket} = state
      ) do
    Logger.error("TCP connection error: #{inspect(reason)}")
    :gen_tcp.close(upstream_socket)
    {:stop, :normal, state}
  end

  def handle_info(
        {:tcp_error, socket, reason},
        %__MODULE__{downstream_socket: downstream_socket, upstream_socket: socket} = state
      ) do
    Logger.error("TCP connection error: #{inspect(reason)}")
    :gen_tcp.close(downstream_socket)
    {:stop, :normal, state}
  end

  @spec handle_new_data(:gen_tcp.socket(), t()) :: {:noreply, t()} | {:stop, :normal, t()}
  defp handle_new_data(
         socket,
         %__MODULE__{
           upstream_socket: socket,
           upstream_buffer: buffer
         } = state
       ) do
    do_handle_new_data(:upstream_buffer, buffer, state)
  end

  defp handle_new_data(
         socket,
         %__MODULE__{
           downstream_socket: socket,
           downstream_buffer: buffer
         } = state
       ) do
    do_handle_new_data(:downstream_buffer, buffer, state)
  end

  @spec do_handle_new_data(atom(), binary(), t()) :: {:noreply, t()} | {:stop, :normal, t()}
  defp do_handle_new_data(buffer_key, buffer, state) do
    case String.split(buffer, ["\r\n", "\n"], parts: 2) do
      [line, rest] ->
        new_state = put_in(state, [Access.key!(buffer_key)], rest)

        buffer_key
        |> boguscoin_rewriter()
        |> send_message(line, new_state)

      _ ->
        {:noreply, state}
    end
  end

  @spec send_message(String.t(), atom(), t()) ::
          {:noreply, t()} | {:stop, :normal, t()}
  defp send_message(
         message,
         :upstream_buffer,
         state
       ) do
    :gen_tcp.send(state.downstream_socket, message <> "\n")
    handle_new_data(state.upstream_socket, state)
  end

  defp send_message(
         message,
         :downstream_buffer,
         state
       ) do
    :gen_tcp.send(state.upstream_socket, message <> "\n")
    handle_new_data(state.downstream_socket, state)
  end

  defp boguscoin_rewriter(message) do
    String.replace(message, ~r/(7[a-zA-Z0-9]{25,34})/, "7YWHMfk9JZe0LM0g1ZauHuiSxhI")
  end
end
