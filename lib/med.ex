defmodule Med do
  @moduledoc """
  The main module of the application, provides the `check/1` function.
  """

  alias Med.Data.Claude
  alias Med.Data.FDA
  alias Med.Data.PubMed
  alias Med.Data.RLSNet

  @spec check(String.t()) :: Med.Drug.t()
  def check(name) do
    name
    |> RLSNet.fetch()
    |> fetch_info()
    |> calculate_research_score()
  end

  defp fetch_info(%{homeopathy: true} = drug), do: drug
  defp fetch_info(%{active_ingredient: nil} = drug), do: drug

  defp fetch_info(drug) do
    drug
    |> FDA.get_approval()
    |> PubMed.get_research()
    |> Claude.summarize_research()
  end

  defp calculate_research_score(drug) do
    fda_score = if drug.fda_approved, do: 40, else: 0
    cochrane_score = drug.cochrane * 10

    score = min(fda_score + cochrane_score + drug.pubmed, 100)

    %{drug | research_score: score}
  end
end
