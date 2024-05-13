defmodule CFSync.RichText do
  @moduledoc """
  RichText recursive struct

  RichText in Contentful is implemented as a tree of nodes.
  All nodes share a common structure and some of them have specific properties.
  Here I chosed to represent all nodes with a single struct for simplicity.
  """

  alias CFSync.Link

  defstruct type: :document,
            content: [],
            value: nil,
            marks: [],
            target: nil,
            uri: nil,
            colspan: 0,
            rowspan: 0

  @type marks ::
          :bold
          | :italic
          | :underline
          | :code

  @type node_types ::
          :document
          | :paragraph
          | :heading_1
          | :heading_2
          | :heading_3
          | :heading_4
          | :heading_5
          | :heading_6
          | :ol_list
          | :ul_list
          | :list_item
          | :hr
          | :quote
          | :embedded_entry
          | :embedded_asset
          | :table
          | :table_row
          | :table_cell
          | :table_header_cell
          | :hyperlink
          | :entry_hyperlink
          | :asset_hyperlink
          | :embedded_entry_inline
          | :text

  @type t :: %__MODULE__{
          type: node_types(),
          content: list(t()),
          value: binary(),
          marks: list(marks()),
          target: nil | Link.t(),
          uri: nil | binary(),
          colspan: integer(),
          rowspan: integer()
        }

  @spec new(:empty | map, CFSync.store(), atom()) :: t()
  def new(data, store, locale) when is_map(data) do
    create(data)
    |> maybe_add_content(data, store, locale)
    |> maybe_add_value(data)
    |> maybe_add_marks(data)
    |> maybe_add_target(data, store, locale)
    |> maybe_add_uri(data)
    |> maybe_add_colspan(data)
    |> maybe_add_rowspan(data)
  end

  def new(:empty, _store, _locale), do: new(:empty)

  def new(:empty) do
    create(%{
      "nodeType" => "document",
      "content" => []
    })
  end

  @doc """
  Maps node recursively using the provided function.

  The provided function should accept a node and return a new node.
  """
  @spec map(t(), function()) :: t()
  def map(%__MODULE__{} = node, mapper) do
    case mapper.(node) do
      %__MODULE__{content: []} = node ->
        node

      %__MODULE__{content: children} = node ->
        children = Enum.map(children, &map(&1, mapper))
        %__MODULE__{node | content: children}
    end
  end

  defp create(data), do: %__MODULE__{type: type(data)}

  defp maybe_add_content(node, %{"content" => content}, store, locale) when is_list(content),
    do: %__MODULE__{node | content: Enum.map(content, &new(&1, store, locale))}

  defp maybe_add_content(node, _data, _store, _locale), do: node

  defp maybe_add_target(node, %{"data" => %{"target" => link_data}}, store, locale),
    do: %__MODULE__{node | target: Link.new(link_data, store, locale)}

  defp maybe_add_target(node, _data, _store, _locale), do: node

  defp maybe_add_uri(node, %{"data" => %{"uri" => uri}}) when is_binary(uri),
    do: %__MODULE__{node | uri: uri}

  defp maybe_add_uri(node, _data), do: node

  defp maybe_add_colspan(node, %{"data" => %{"colspan" => colspan}}) when is_integer(colspan),
    do: %__MODULE__{node | colspan: colspan}

  defp maybe_add_colspan(node, _data), do: node

  defp maybe_add_rowspan(node, %{"data" => %{"rowspan" => rowspan}}) when is_integer(rowspan),
    do: %__MODULE__{node | rowspan: rowspan}

  defp maybe_add_rowspan(node, _data), do: node

  defp maybe_add_value(node, %{"value" => v}) when is_binary(v) do
    value =
      v
      |> Phoenix.HTML.html_escape()
      |> Phoenix.HTML.safe_to_string()

    %__MODULE__{node | value: value}
  end

  defp maybe_add_value(node, _data), do: node

  defp maybe_add_marks(node, %{"marks" => marks}) when is_list(marks),
    do: %__MODULE__{node | marks: Enum.map(marks, &mark/1)}

  defp maybe_add_marks(node, _data), do: node

  defp mark(%{"type" => "bold"}), do: :bold
  defp mark(%{"type" => "italic"}), do: :italic
  defp mark(%{"type" => "underline"}), do: :underline
  defp mark(%{"type" => "code"}), do: :code

  defp type(%{"nodeType" => "document"}), do: :document
  defp type(%{"nodeType" => "paragraph"}), do: :paragraph
  defp type(%{"nodeType" => "heading-1"}), do: :heading_1
  defp type(%{"nodeType" => "heading-2"}), do: :heading_2
  defp type(%{"nodeType" => "heading-3"}), do: :heading_3
  defp type(%{"nodeType" => "heading-4"}), do: :heading_4
  defp type(%{"nodeType" => "heading-5"}), do: :heading_5
  defp type(%{"nodeType" => "heading-6"}), do: :heading_6
  defp type(%{"nodeType" => "ordered-list"}), do: :ol_list
  defp type(%{"nodeType" => "unordered-list"}), do: :ul_list
  defp type(%{"nodeType" => "list-item"}), do: :list_item
  defp type(%{"nodeType" => "hr"}), do: :hr
  defp type(%{"nodeType" => "blockquote"}), do: :quote
  defp type(%{"nodeType" => "embedded-entry-block"}), do: :embedded_entry
  defp type(%{"nodeType" => "embedded-asset-block"}), do: :embedded_asset
  defp type(%{"nodeType" => "table"}), do: :table
  defp type(%{"nodeType" => "table-row"}), do: :table_row
  defp type(%{"nodeType" => "table-cell"}), do: :table_cell
  defp type(%{"nodeType" => "table-header-cell"}), do: :table_header_cell
  defp type(%{"nodeType" => "hyperlink"}), do: :hyperlink
  defp type(%{"nodeType" => "entry-hyperlink"}), do: :entry_hyperlink
  defp type(%{"nodeType" => "asset-hyperlink"}), do: :asset_hyperlink
  defp type(%{"nodeType" => "embedded-entry-inline"}), do: :embedded_entry_inline
  defp type(%{"nodeType" => "text"}), do: :text
end
