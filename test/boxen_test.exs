defmodule BoxenTest do
  use ExUnit.Case
  doctest Boxen

  randomText = "lewb{+^PN_6-l 8eK2eqB:jn^YFgGl;wuT)mdA9TZlf 9}?X#P49`x\"@+nLx:BH5p{5_b`S\'E8\0{A0l\"(62`TIf(z8n2arEY~]y|bk,6,FYf~rGY*Xfa00q{=fdm=4.zVf6#\'|3S!`pJ3 6y02]nj2o4?-`1v$mudH?Wbw3fZ]a+aE\'\'P4Q(6:NHBry)L_&/7v]0<!7<kw~gLc.)\'ajS>\0~y8PZ*|-BRY&m%UaCe\'3A,N?8&wbOP}*.O<47rnPzxO=4\"*|[%A):;E)Z6!V&x!1*OprW-*+q<F$6|864~1HmYX@J#Nl1j1`!$Y~j^`j;PB2qpe[_;.+vJGnE3) yo&5qRI~WHxK~r%+\'P>Up&=P6M<kDdpSL#<Ur/[NN0qI3dFEEy|>_VGx0O/VOvPEez:7C58a^.N,\"Rxc|a6C[i$3QC_)~x!wd+ZMtYsGF&?"

  test "without any args" do
    assert Boxen.boxify("hello, elixir") ==
             {:ok, "┌─────────────┐\n│hello, elixir│\n└─────────────┘"}
  end

  test "with title" do
    assert Boxen.boxify("hello, elixir", title: "Message") ==
             {:ok, "┌ Message ────┐\n│hello, elixir│\n└─────────────┘"}
  end
  
  test "with title and title aligment center" do
    assert Boxen.boxify("hello, elixir", title: "Message", title_alignment: :center) ==
             {:ok, "┌── Message ──┐\n│hello, elixir│\n└─────────────┘"}
  end
  
  test "with title and title aligment right" do
    assert Boxen.boxify("hello, elixir", title: "Message", title_alignment: :right) ==
             {:ok, "┌──── Message ┐\n│hello, elixir│\n└─────────────┘"}
  end
end
