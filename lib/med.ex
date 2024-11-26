defmodule Med do
  @moduledoc """
  The main module of the application, provides the `check/1` function.
  """

  alias Med.Data.Claude
  alias Med.Data.FDA
  alias Med.Data.PubMed
  alias Med.Data.RLSNet

  @spec check(String.t(), pid()) :: Med.Drug.t() | nil
  def check(name, live_pid) do
    name
    |> RLSNet.fetch()
    |> fetch_info(live_pid)
    |> cache()
  end

  def cache(nil), do: nil

  @spec cache(Med.Drug.t()) :: Med.Drug.t()
  def cache(drug) do
    Cachex.put(:med, drug.name, drug)
    Cachex.save(:med, "cache.dat")
    drug
  end

  defp fetch_info(nil, _live_pid), do: nil
  defp fetch_info(%{homeopathy: true} = drug, _live_pid), do: drug
  defp fetch_info(%{active_ingredient: nil} = drug, _live_pid), do: drug

  defp fetch_info(drug, live_pid) do
    case Cachex.get(:med, drug.name) do
      {:ok, nil} ->
        drug
        |> FDA.get_approval()
        |> PubMed.get_research()
        |> Claude.summarize_research(live_pid)
        |> calculate_research_score()
        |> cache()

      {:ok, %{summary: ""} = drug} ->
        drug
        |> PubMed.get_research()
        |> Claude.summarize_research(live_pid)
        |> cache()

      {:ok, drug} ->
        drug
    end
  end

  defp calculate_research_score(drug) do
    fda_score = if drug.fda_approved, do: 40, else: 0
    cochrane_score = drug.cochrane * 10

    score = min(fda_score + cochrane_score + drug.pubmed, 100)

    %{drug | research_score: score}
  end
end
