defmodule XombiServer.Decoder do

  def decode(json) do
    %{ "msgType" => msgType, "username" => username, "message" => message } = Poison.Parser.parse!(json)

    case msgType do
      3 -> {:ok, username, message}
      _ -> {:error, "Invalid message"}
    end

  end

end
