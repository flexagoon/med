defmodule Med do
  alias Med.Data.PubMed
  alias Med.Data.FDA
  alias Med.Data.RLSNet

  def check(name) do
    RLSNet.fetch(name) |> fetch_info()
  end

  defp fetch_info(%{homeopathy: true} = drug), do: drug
  defp fetch_info(%{active_ingredient: nil} = drug), do: drug

  defp fetch_info(drug) do
    drug |> FDA.get_approval() |> PubMed.get_research()
  end
  end
end
