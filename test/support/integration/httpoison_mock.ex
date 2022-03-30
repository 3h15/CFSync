defmodule CFSyncTest.Integration.HTTPoisonMock do
  @behaviour CFSyncTest.HTTPoisonBehaviour

  alias CFSyncTest.Integration.HTTPoisonMock.DataInitial
  alias CFSyncTest.Integration.HTTPoisonMock.DataDelta1
  alias CFSyncTest.Integration.HTTPoisonMock.DataDelta2

  def request(%HTTPoison.Request{
        method: :get,
        headers: [
          {"Content-Type", "application/json"},
          {"authorization", "Bearer unC_qLLrGg1iSOK1mHU0IUenA-Ji3deWGjp3H8VRSQA"}
        ],
        options: [ssl: [{:versions, [:"tlsv1.2"]}]],
        url: "https://cdn.contentful.com/spaces/diw11gmz6opc/sync/?initial=true"
      }) do
    data!(DataInitial)
  end

  def request(%HTTPoison.Request{
        method: :get,
        headers: [
          {"Content-Type", "application/json"},
          {"authorization", "Bearer unC_qLLrGg1iSOK1mHU0IUenA-Ji3deWGjp3H8VRSQA"}
        ],
        options: [ssl: [{:versions, [:"tlsv1.2"]}]],
        url: "delta_1"
      }) do
    data!(DataDelta1)
  end

  def request(%HTTPoison.Request{
        method: :get,
        headers: [
          {"Content-Type", "application/json"},
          {"authorization", "Bearer unC_qLLrGg1iSOK1mHU0IUenA-Ji3deWGjp3H8VRSQA"}
        ],
        options: [ssl: [{:versions, [:"tlsv1.2"]}]],
        url: "delta_2"
      }) do
    data!(DataDelta2)
  end

  defp data!(module) do
    {:ok, %{status_code: 200, body: module.payload}}
  end
end
