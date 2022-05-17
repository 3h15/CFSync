defmodule CFSync.RichTextRendererTest do
  use ExUnit.Case, async: true

  doctest CFSync.RichTextRenderer

  alias CFSync.RichText

  alias CFSync.RichTextRenderer

  use Phoenix.Component

  test "Renders text" do
    assert_renders(
      %RichText{
        type: :text,
        value: "Un"
      },
      ~s(Un)
    )
  end

  test "Renders marks" do
    assert_renders(
      %RichText{
        type: :text,
        value: "Deux",
        marks: [:bold]
      },
      ~s(<b>Deux</b>)
    )

    assert_renders(
      %RichText{
        type: :text,
        value: "Trois",
        marks: [:italic, :underline, :code]
      },
      ~s(<code><u><i>Trois</i></u></code>)
    )
  end

  test "Renders paragraphs" do
    assert_renders(
      %RichText{
        type: :paragraph,
        content: [
          %RichText{
            type: :text,
            value: "inner"
          }
        ]
      },
      ~s(<p>inner</p>)
    )
  end

  test "Renders headers" do
    for i <- 1..6 do
      assert_renders(
        %RichText{
          type: String.to_atom("heading_#{i}"),
          content: [
            %RichText{
              type: :text,
              value: "inner"
            }
          ]
        },
        ~s(<h#{i}>inner</h#{i}>)
      )
    end
  end

  test "Renders ordered lists" do
    assert_renders(
      %RichText{
        type: :ol_list,
        content: [
          %RichText{
            type: :list_item,
            content: [
              %RichText{
                type: :text,
                value: "inner 1"
              }
            ]
          },
          %RichText{
            type: :list_item,
            content: [
              %RichText{
                type: :text,
                value: "inner 2"
              }
            ]
          }
        ]
      },
      ~s(<ol><li>inner 1</li><li>inner 2</li></ol>)
    )
  end

  test "Renders unordered lists" do
    assert_renders(
      %RichText{
        type: :ul_list,
        content: [
          %RichText{
            type: :list_item,
            content: [
              %RichText{
                type: :text,
                value: "inner 1"
              }
            ]
          },
          %RichText{
            type: :list_item,
            content: [
              %RichText{
                type: :text,
                value: "inner 2"
              }
            ]
          }
        ]
      },
      ~s(<ul><li>inner 1</li><li>inner 2</li></ul>)
    )
  end

  test "Renders tables" do
    assert_renders(
      %RichText{
        type: :table,
        content: [
          %RichText{
            type: :table_row,
            content: [
              %RichText{
                type: :table_header_cell,
                content: [
                  %RichText{
                    type: :text,
                    value: "inner 1"
                  }
                ]
              },
              %RichText{
                type: :table_cell,
                content: [
                  %RichText{
                    type: :text,
                    value: "inner 2"
                  }
                ]
              }
            ]
          },
          %RichText{
            type: :table_row,
            content: [
              %RichText{
                type: :table_cell,
                content: [
                  %RichText{
                    type: :text,
                    value: "inner 3"
                  }
                ]
              },
              %RichText{
                type: :table_cell,
                content: [
                  %RichText{
                    type: :text,
                    value: "inner 4"
                  }
                ]
              }
            ]
          }
        ]
      },
      ~s(<table><tr><th>inner 1</th><td>inner 2</td></tr><tr><td>inner 3</td><td>inner 4</td></tr></table>)
    )
  end

  test "Renders hr" do
    assert_renders(
      %RichText{
        type: :hr
      },
      ~s(<hr>)
    )
  end

  test "Renders quotes" do
    assert_renders(
      %RichText{
        type: :quote,
        content: [
          %RichText{
            type: :text,
            value: "inner"
          }
        ]
      },
      ~s(<blockquote>inner</blockquote>)
    )
  end

  test "Renders hyperlinks" do
    assert_renders(
      %RichText{
        type: :hyperlink,
        uri: "https://example.com",
        content: [
          %RichText{
            type: :text,
            value: "inner"
          }
        ]
      },
      ~s(<a href="https://example.com">inner</a>)
    )
  end

  test "Renders unimplemented type" do
    assert_renders(
      %RichText{
        type: :unimplemented_node_type,
        content: [
          %RichText{
            type: :paragraph,
            content: [
              %RichText{
                type: :text,
                value: "inner"
              }
            ]
          }
        ]
      },
      """
      <div style="border: 2px solid red;">
        <div style="background-color: red; color: white; font-weight: bold; padding: .25rem;">
          Missing component for unimplemented_node_type
        </div>
        <div><p>inner</p></div>
      </div>\
      """
    )
  end

  test "Uses delegate module" do
    assert_renders(
      %RichText{
        type: :paragraph,
        content: [
          %RichText{
            type: :text,
            value: "inner"
          }
        ]
      },
      ~s(<p class="custom">inner</p>),
      __MODULE__
    )
  end

  test "Passes assigns through hierachy" do
    assert_renders(
      %RichText{
        type: :paragraph,
        content: [
          %RichText{
            type: :blockquote,
            content: [
              %RichText{
                type: :text,
                value: "inner"
              }
            ]
          }
        ]
      },
      ~s(<p class="custom"><blockquote class="cutom_bl\">inner</blockquote></p>),
      __MODULE__,
      %{blockquote_class: "cutom_bl"}
    )
  end

  def paragraph(assigns) do
    ~H"""
    <p class="custom"><%= render_slot @inner_block %></p>
    """
  end

  def blockquote(assigns) do
    ~H"""
    <blockquote class={@blockquote_class}><%= render_slot @inner_block %></blockquote>
    """
  end

  defp assert_renders(rich_text, expected_html, delegate \\ nil, extra_assigns \\ %{}) do
    rich_text = %RichText{
      type: :document,
      content: [rich_text]
    }

    generated_html =
      extra_assigns
      |> Map.merge(%{
        content: rich_text,
        class: "root_rt_class",
        delegate: delegate
      })
      |> render()

    assert generated_html == ~s(<div class="root_rt_class">#{expected_html}</div>)
  end

  defp render(assigns),
    do:
      assigns
      |> render_component()
      |> Phoenix.HTML.html_escape()
      |> Phoenix.HTML.safe_to_string()

  defp render_component(assigns) do
    ~H"<RichTextRenderer.render {assigns} />"
  end
end
