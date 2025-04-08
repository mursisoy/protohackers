defmodule PrimeTimeTest do
  use ExUnit.Case

  test "returns valid truthy response when number is prime" do
    {:ok, socket} =
      :gen_tcp.connect(~c"localhost", 4000, [:binary, active: false])

    assert :ok =
             :gen_tcp.send(socket, Jason.encode!(%{"method" => "isPrime", "number" => 5}) <> "\n")

    {:ok, response} = :gen_tcp.recv(socket, 0, 5_000)
    assert response == Jason.encode!(%{"method" => "isPrime", "prime" => true}) <> "\n"
  end
end
