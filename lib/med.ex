defmodule Med do
  alias Med.Data.PubMed
  alias Med.Data.FDA
  alias Med.Data.RLSNet

  def check(name) do
    drug = RLSNet.fetch(name) |> fetch_info()
    research_score = calculate_research_score(drug)
    {drug, research_score}
  end

  defp fetch_info(%{homeopathy: true} = drug), do: drug
  defp fetch_info(%{active_ingredient: nil} = drug), do: drug

  defp fetch_info(drug) do
    drug |> FDA.get_approval() |> PubMed.get_research()
  end

  defp calculate_research_score(drug) do
    fda_score = if drug.fda_approved, do: 40, else: 0
    cochrane_score = drug.cochrane * 10

    min(fda_score + cochrane_score + drug.pubmed, 100)
  end
end
