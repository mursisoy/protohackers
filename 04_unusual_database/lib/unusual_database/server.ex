defmodule UnusualDatabase.Server do
  use GenServer

  alias UnusualDatabase.Database

  require Logger

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, options)
  end

  @impl true
  def init(options) do
    port = Keyword.fetch!(options, :port)

    {:ok, addr} = :inet.getaddr(~c"fly-global-services", :inet)

    options = [
      :binary,
      active: true,
      ip: addr
    ]

    {:ok, socket} = :gen_udp.open(port, options)

    {:ok, actual_port} = :inet.port(socket)
    Logger.info("Unusual Database server started on port: #{actual_port}")

    {:ok, socket}
  end

  @impl true
  def handle_info(
        {:udp, socket, ip, port, "version"},
        socket
      ) do
    :gen_udp.send(socket, ip, port, "version=Ken's Key-Value Store 1.0")
    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:udp, socket, ip, port, request},
        socket
      ) do
    Logger.info("Received database request from #{:inet.ntoa(ip)}:#{port}, #{request}")

    case String.split(request, "=", parts: 2) do
      [key] ->
        value = Database.get(key)

        :gen_udp.send(socket, ip, port, "#{key}=#{value}")

        Logger.info("Database request completed, key: #{key}=#{value}")

      [key, value] ->
        Database.set(key, value)
        Logger.info("Database updated, key: #{key}=#{value}")
    end

    {:noreply, socket}
  end
end
