defmodule MeansEndTest do
  use ExUnit.Case
  doctest MeansEnd

  test "test Inserts and Query" do
    {:ok, socket} =
      :gen_tcp.connect(~c"localhost", 4000, [:binary, active: false])

    assert :ok =
             :gen_tcp.send(
               socket,
               <<"I", 12345::big-signed-32, 101::big-signed-32>>
             )

    assert :ok =
             :gen_tcp.send(
               socket,
               <<"I", 12346::big-signed-32, 102::big-signed-32>>
             )

    assert :ok =
             :gen_tcp.send(
               socket,
               <<"I", 12347::big-signed-32, 100::big-signed-32>>
             )

    assert :ok =
             :gen_tcp.send(
               socket,
               <<"I", 40960::big-signed-32, 5::big-signed-32>>
             )

    assert :ok =
             :gen_tcp.send(
               socket,
               <<"Q", 12288::big-signed-32, 16384::big-signed-32>>
             )

    {:ok, response} = :gen_tcp.recv(socket, 0, 5_000)
    assert response == <<101::big-signed-32>>
  end
end
