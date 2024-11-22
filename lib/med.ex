defmodule Med do
  @moduledoc """
  The main module of the application, provides the `check/1` function.
  """

  alias Med.Data.Claude
  alias Med.Data.FDA
  alias Med.Data.PubMed
  alias Med.Data.RLSNet

  @spec check(String.t(), pid()) :: Med.Drug.t()
  def check(name, live_pid) do
    case Cachex.get(:med, name) do
      {:ok, nil} ->
        name
        |> RLSNet.fetch()
        |> fetch_info(live_pid)

      {:ok, drug} ->
        drug
    end
  end

  @spec cache(Med.Drug.t()) :: nil
  def cache(drug) do
    Cachex.put(:med, drug.name, drug)
    Cachex.save(:med, "cache.dat")
    nil
  end

  defp fetch_info(%{homeopathy: true} = drug, _live_pid), do: drug
  defp fetch_info(%{active_ingredient: nil} = drug, _live_pid), do: drug

  defp fetch_info(drug, live_pid) do
    drug
    |> FDA.get_approval()
    |> PubMed.get_research()
    |> Claude.summarize_research(live_pid)
    |> calculate_research_score()
  end

  defp calculate_research_score(drug) do
    fda_score = if drug.fda_approved, do: 40, else: 0
    cochrane_score = drug.cochrane * 10

    score = min(fda_score + cochrane_score + drug.pubmed, 100)

    %{drug | research_score: score}
  end
end
