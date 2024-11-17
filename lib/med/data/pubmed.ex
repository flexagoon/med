defmodule Med.Data.PubMed do
  @moduledoc """
  Module for fetching research papers from PubMed.
  """

  @base_url "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"

  def get_research(drug) do
    cochrane_ids = get_cochrane(drug)
    pubmed_ids = get_regular(drug)

    abstracts = get_abstracts(cochrane_ids ++ pubmed_ids)

    %{
      drug
      | cochrane: length(cochrane_ids),
        pubmed: length(pubmed_ids),
        research: abstracts
    }
  end

  defp get_cochrane(drug) do
    Req.get!("#{@base_url}/esearch.fcgi",
      params: [
        db: "pubmed",
        retmode: "json",
        retmax: 100,
        term: build_query(drug) <> " AND \"Cochrane Database Syst Rev\"[Journal]"
      ]
    ).body["esearchresult"]["idlist"]
  end

  defp get_regular(drug) do
    Req.get!("#{@base_url}/esearch.fcgi",
      params: [
        db: "pubmed",
        retmode: "json",
        retmax: 100,
        term: build_query(drug)
      ]
    ).body["esearchresult"]["idlist"]
  end

  defp build_query(drug),
    do: "(#{drug.active_ingredient}[Title] OR #{drug.name}[Title]) AND fha[Filter]"

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
