defmodule Med.Data.PubMed do
  @moduledoc """
  Module for fetching research papers from PubMed.
  """

  @base_url "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"

  @spec get_research(Med.Drug.t()) :: Med.Drug.t()
  def get_research(drug) do
    cochrane_ids = get_cochrane(drug)

    trade_name_ids = search(drug.name)
    active_ingredient_ids = search(drug.active_ingredient)
    pubmed_ids = Enum.uniq(trade_name_ids ++ active_ingredient_ids)

    abstracts = get_abstracts(cochrane_ids ++ pubmed_ids)

    %{
      drug
      | research: abstracts,
        cochrane: length(cochrane_ids),
        pubmed: length(pubmed_ids)
    }
  end

  defp get_cochrane(drug) do
    Req.get!("#{@base_url}/esearch.fcgi",
      params: [
        db: "pubmed",
        retmode: "json",
        retmax: 100,
        term: """
          (#{drug.active_ingredient}[Title] OR #{drug.name}[Title])
          AND fha[Filter]
          AND "Cochrane Database Syst Rev"[Journal]
        """
      ]
    ).body["esearchresult"]["idlist"]
  end

  # When the name is too short, the search results may be unrelated.
  defp search(name) when length(name) < 5, do: []

  defp search(nil), do: []

  defp search(name) do
    Req.get!("#{@base_url}/esearch.fcgi",
      params: [
        db: "pubmed",
        retmode: "json",
        retmax: 100,
        term: """
          #{name}[Title/Abstract]
          AND ("randomized controlled trial"[Publication Type] OR "meta analysis"[Publication Type])
          AND fha[Filter]
          NOT "Cochrane Database Syst Rev"[Journal]
        """
      ]
    ).body["esearchresult"]["idlist"]
  end

  defp get_abstracts([]), do: []

  defp get_abstracts(ids) do
    abstracts =
      Req.get!("#{@base_url}/efetch.fcgi",
        params: [
          db: "pubmed",
          rettype: "abstract",
          retmode: "text",
          id: Enum.join(ids, ",")
        ]
      ).body

    String.split(abstracts, "\n\n\n")
  end
end
