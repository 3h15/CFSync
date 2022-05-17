defmodule CFSync.RichTextRenderer do
  @moduledoc """
  Phoenix components for CFSync RichText rendering.

  BEWARE OF WHITESPACE
  It is essential to avoid adding whitespace to the text content.
  We use white-space: pre-line; to render line breaks added to rich text.
  Adding line breaks here in the markup would propagate blank lines to the pages.
  """
  use Phoenix.Component
  use Phoenix.HTML

  def render(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:delegate, fn -> false end)

    if assigns.delegate do
      {:module, _mod} = Code.ensure_loaded(assigns.delegate)
    end

    ~H"""
    <div class={@class}><.rt_node_content {assigns} node={@content} /></div>
    """
  end

  defp rt_node_content(assigns) do
    ~H"""
    <%= for node <- @node.content do %><.rt_node_switch {assigns} node={node}><.rt_node_content {assigns} node={node} /></.rt_node_switch><% end %>
    """
  end

  defp rt_node_switch(%{node: %{type: "text"}} = assigns), do: rt_node(assigns)

  defp rt_node_switch(%{node: %{type: type}} = assigns) do
    if assigns.delegate && function_exported?(assigns.delegate, type, 1) do
      apply(assigns.delegate, type, [assigns])
    else
      rt_node(assigns)
    end
  end

  defp rt_mark_switch(assigns, mark) do
    if assigns.delegate && function_exported?(assigns.delegate, mark, 1) do
      apply(assigns.delegate, mark, [assigns])
    else
      case mark do
        :bold -> bold(assigns)
        :italic -> italic(assigns)
        :underline -> underline(assigns)
        :code -> code(assigns)
      end
    end
  end

  defp bold(assigns) do
    ~H"<b><%= render_slot @inner_block %></b>"
  end

  defp italic(assigns) do
    ~H"<i><%= render_slot @inner_block %></i>"
  end

  defp underline(assigns) do
    ~H"<u><%= render_slot @inner_block %></u>"
  end

  defp code(assigns) do
    ~H"<code><%= render_slot @inner_block %></code>"
  end

  defp rt_node(%{node: %{type: :text}} = assigns) do
    for mark <- assigns.node.marks, reduce: ~H"<%= raw @node.value %>" do
      acc ->
        %{
          assigns
          | inner_block: [
              %{
                __slot__: :inner_block,
                inner_block: inner_block(:inner_block, do: acc)
              }
            ]
        }
        |> rt_mark_switch(mark)
    end
  end

  defp rt_node(%{node: %{type: :paragraph}} = assigns) do
    ~H"""
    <p><%= render_slot @inner_block %></p>
    """
  end

  defp rt_node(%{node: %{type: :heading_1}} = assigns) do
    ~H"""
    <h1><%= render_slot @inner_block %></h1>
    """
  end

  defp rt_node(%{node: %{type: :heading_2}} = assigns) do
    ~H"""
    <h2><%= render_slot @inner_block %></h2>
    """
  end

  defp rt_node(%{node: %{type: :heading_3}} = assigns) do
    ~H"""
    <h3><%= render_slot @inner_block %></h3>
    """
  end

  defp rt_node(%{node: %{type: :heading_4}} = assigns) do
    ~H"""
    <h4><%= render_slot @inner_block %></h4>
    """
  end

  defp rt_node(%{node: %{type: :heading_5}} = assigns) do
    ~H"""
    <h5><%= render_slot @inner_block %></h5>
    """
  end

  defp rt_node(%{node: %{type: :heading_6}} = assigns) do
    ~H"""
    <h6><%= render_slot @inner_block %></h6>
    """
  end

  defp rt_node(%{node: %{type: :ol_list}} = assigns) do
    ~H"""
    <ol><%= render_slot @inner_block %></ol>
    """
  end

  defp rt_node(%{node: %{type: :ul_list}} = assigns) do
    ~H"""
    <ul><%= render_slot @inner_block %></ul>
    """
  end

  defp rt_node(%{node: %{type: :list_item}} = assigns) do
    ~H"""
    <li><%= render_slot @inner_block %></li>
    """
  end

  defp rt_node(%{node: %{type: :table}} = assigns) do
    ~H"""
    <table><%= render_slot @inner_block %></table>
    """
  end

  defp rt_node(%{node: %{type: :table_row}} = assigns) do
    ~H"""
    <tr><%= render_slot @inner_block %></tr>
    """
  end

  defp rt_node(%{node: %{type: :table_header_cell}} = assigns) do
    ~H"""
    <th><%= render_slot @inner_block %></th>
    """
  end

  defp rt_node(%{node: %{type: :table_cell}} = assigns) do
    ~H"""
    <td><%= render_slot @inner_block %></td>
    """
  end

  defp rt_node(%{node: %{type: :hr}} = assigns) do
    ~H"""
    <hr />
    """
  end

  defp rt_node(%{node: %{type: :quote}} = assigns) do
    ~H"""
    <blockquote><%= render_slot @inner_block %></blockquote>
    """
  end

  defp rt_node(%{node: %{type: :hyperlink}} = assigns) do
    ~H"""
    <a href={@node.uri}><%= render_slot @inner_block %></a>
    """
  end

  defp rt_node(%{node: %{type: unimplemented_type}} = assigns) do
    ~H"""
    <div style="border: 2px solid red;">
      <div style="background-color: red; color: white; font-weight: bold; padding: .25rem;">
        Missing component for <%= unimplemented_type %>
      </div>
      <div><%= render_slot @inner_block %></div>
    </div>
    """
  end
end
