defmodule Med.Data.MedIQLab do
  @moduledoc """
  Module for fetching drug information from MediQLab.
  """

  alias Med.Drug

  @spec fetch(String.t()) :: Drug.t() | nil
  def fetch(name) do
    access_token =
      Req.post!("https://mediqlab.com/auth/new",
        json: %{
          "clientId" => "mediq-svc",
          "realm" => "MedIQ",
          "usr" => "site2",
          "psw" => "SoLnJ3mp5cxaNqnY"
        }
      ).body["accessToken"]

    drug_data =
      Req.post!("https://mediqlab.com/exapi/gql",
        headers: [{"Authorization", "Bearer #{access_token}"}],
        json: %{
          "query" => """
            fragment MnnFragment on MnnInfo {
              name
              quality
              criterions {
                criterion
                points
                url
              }
            }

            query {
              fuzzyMatch(names: ["#{name}"], types: [DRUG]) {
                drug {
                  name
                  type
                  description
                  mnn {
                    ...MnnFragment
                    complex { ...MnnFragment }
                  }
                }
              }
            }
          """
        }
      ).body
      |> get_in(["data", "fuzzyMatch", Access.at(0), "drug"])

    case drug_data do
      nil ->
        nil

      %{"name" => name, "type" => "HOMEOPATHY"} ->
        %Drug{name: name, type: :homeopathy}

      %{"name" => name, "type" => "BIO_ACTIVE_SUPPLEMENTS"} ->
        %Drug{name: name, type: :supplement}

      %{"name" => name, "description" => description, "mnn" => mnn} ->
        parse_drug(mnn, name, description)
    end
  end

  defp parse_drug(%{"complex" => []} = mnn, name, description) do
    pubmed_url =
      mnn["criterions"]
      |> Enum.find(&(&1["criterion"] == "PUBMED"))
      |> Map.get("url")

    who_list =
      Enum.any?(
        mnn["criterions"],
        &((&1["criterion"] == "WHO_ADULT_LIST" or
             &1["criterion"] == "WHO_KIDS_LIST") and
            &1["points"] == 1)
      )

    case Regex.run(~r/(?<=term=)[\w+-]+/, pubmed_url) do
      nil ->
        nil

      [term] ->
        %Drug{
          type: :drug,
          name: name,
          active_ingredient: %{en: String.replace(term, "+", " "), ru: mnn["name"]},
          proven: mnn["quality"] == "PROVED",
          description: description,
          who_list: who_list
        }
    end
  end

  defp parse_drug(%{"complex" => [mnn | _other_ingredients]}, name, description),
    do: parse_drug(mnn, name, description)

  defp parse_drug(mnn, name, description),
    do: parse_drug(Map.put(mnn, "complex", []), name, description)
end
