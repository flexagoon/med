defmodule Med do
  @moduledoc """
  The main module of the application, provides the `check/1` function.
  """

  alias Med.Data.FDA
  alias Med.Data.LLM
  alias Med.Data.PubMed
  alias Med.Data.RLSNet

  @spec check(String.t(), pid()) :: Med.Drug.t() | nil
  def check(name, live_pid) do
    name
    |> RLSNet.fetch()
    |> fetch_info(live_pid)
  end

  def cache(nil), do: nil

  @seconds_in_half_year 6 * 30 * 24 * 60 * 60

  @spec cache(Med.Drug.t()) :: Med.Drug.t()
  def cache(drug) do
    data = :erlang.term_to_binary(drug)
    Redix.command!(:redix, ["SET", drug.name, data, "EX", @seconds_in_half_year])

    drug
  end

  defp get_cache(name) do
    case Redix.command!(:redix, ["GET", name]) do
      nil -> nil
      drug -> :erlang.binary_to_term(drug)
    end
  end

  defp fetch_info(nil, _live_pid), do: nil
  defp fetch_info(%{homeopathy: true} = drug, _live_pid), do: drug
  defp fetch_info(%{active_ingredient: nil} = drug, _live_pid), do: drug

  defp fetch_info(drug, live_pid) do
    case get_cache(drug.name) do
      nil ->
        drug
        |> FDA.get_approval()
        |> PubMed.get_research()
        |> calculate_research_score()
        |> LLM.summarize_research(live_pid)
        |> cache()

      %{summary: "", research: [_ | _]} = drug ->
        LLM.summarize_research(drug, live_pid)
        |> cache()

      drug ->
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
