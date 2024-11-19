defmodule Med.Data.FDA do
  @moduledoc """
  Module for fetching FDA approval status from FDA.
  """

  @spec get_approval(Med.Drug.t()) :: Med.Drug.t()
  def get_approval(drug) do
    response =
      Req.get!("https://api.fda.gov/drug/drugsfda.json",
        params: [
          limit: 1,
          search: "openfda.substance_name:#{drug.active_ingredient}"
        ]
      )

    case response.body["results"] do
      nil -> drug
      [] -> drug
      [_result] -> %{drug | fda_approved: true}
    end
  end
end
