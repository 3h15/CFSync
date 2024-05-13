defmodule CFSync.RichTextTest do
  use ExUnit.Case, async: true

  doctest CFSync.RichText

  alias CFSync.RichText
  alias CFSync.Link

  test "new(:empty) creates a valid empty RichText struct" do
    assert %RichText{
             type: :document,
             content: []
           } = RichText.new(:empty)
  end

  test "new(:empty, store, locale) creates a valid empty RichText struct" do
    store = make_ref()

    assert %RichText{
             type: :document,
             content: []
           } = RichText.new(:empty, store, :fr)
  end

  test "new/3 recursively maps rich text nodes as expected" do
    document = %{
      "nodeType" => "document",
      "content" => [
        %{
          "nodeType" => "paragraph",
          "content" => [
            %{
              "nodeType" => "text",
              "value" => "Un"
            },
            %{
              "nodeType" => "text",
              "value" => "Deux",
              "marks" => [%{"type" => "bold"}]
            },
            %{
              "nodeType" => "text",
              "value" => "Trois",
              "marks" => [%{"type" => "italic"}, %{"type" => "underline"}, %{"type" => "code"}]
            },
            %{
              "nodeType" => "heading-1",
              "content" => []
            },
            %{
              "nodeType" => "heading-2",
              "content" => []
            },
            %{
              "nodeType" => "heading-3",
              "content" => []
            },
            %{
              "nodeType" => "heading-4",
              "content" => []
            },
            %{
              "nodeType" => "heading-5",
              "content" => []
            },
            %{
              "nodeType" => "heading-6",
              "content" => []
            }
          ]
        },
        %{
          "nodeType" => "hr"
        },
        %{
          "nodeType" => "ordered-list",
          "content" => [
            %{
              "nodeType" => "list-item",
              "content" => []
            }
          ]
        },
        %{
          "nodeType" => "unordered-list",
          "content" => [
            %{
              "nodeType" => "list-item",
              "content" => []
            }
          ]
        },
        %{
          "nodeType" => "table",
          "content" => [
            %{
              "nodeType" => "table-row",
              "content" => [
                %{
                  "nodeType" => "table-header-cell",
                  "data" => %{"colspan" => 2, "rowspan" => 3}
                },
                %{
                  "nodeType" => "table-cell"
                },
                %{
                  "nodeType" => "table-cell",
                  "data" => %{"colspan" => 4}
                },
                %{
                  "nodeType" => "table-cell",
                  "data" => %{"rowspan" => 5}
                }
              ]
            }
          ]
        },
        %{
          "nodeType" => "hyperlink",
          "data" => %{"uri" => "http://example.com"},
          "content" => []
        },
        %{
          "nodeType" => "blockquote",
          "content" => []
        },
        %{
          "nodeType" => "embedded-entry-block",
          "data" => %{
            "target" => %{
              "sys" => %{
                "linkType" => "Entry",
                "id" => "entry_id_1"
              }
            }
          }
        },
        %{
          "nodeType" => "embedded-asset-block",
          "data" => %{
            "target" => %{
              "sys" => %{
                "linkType" => "Asset",
                "id" => "asset_id_1"
              }
            }
          }
        },
        %{
          "nodeType" => "embedded-entry-inline",
          "content" => []
        },
        %{
          "nodeType" => "entry-hyperlink",
          "content" => []
        },
        %{
          "nodeType" => "asset-hyperlink",
          "content" => []
        }
      ]
    }

    store = make_ref()

    rt = RichText.new(document, store, :en)

    assert %RichText{
             type: :document,
             content: [
               %RichText{
                 type: :paragraph,
                 content: [
                   %RichText{
                     type: :text,
                     value: "Un"
                   },
                   %RichText{
                     type: :text,
                     value: "Deux",
                     marks: [:bold]
                   },
                   %RichText{
                     type: :text,
                     value: "Trois",
                     marks: [:italic, :underline, :code]
                   },
                   %RichText{
                     type: :heading_1,
                     content: []
                   },
                   %RichText{
                     type: :heading_2,
                     content: []
                   },
                   %RichText{
                     type: :heading_3,
                     content: []
                   },
                   %RichText{
                     type: :heading_4,
                     content: []
                   },
                   %RichText{
                     type: :heading_5,
                     content: []
                   },
                   %RichText{
                     type: :heading_6,
                     content: []
                   }
                 ]
               },
               %RichText{
                 type: :hr
               },
               %RichText{
                 type: :ol_list,
                 content: [
                   %RichText{
                     type: :list_item,
                     content: []
                   }
                 ]
               },
               %RichText{
                 type: :ul_list,
                 content: [
                   %RichText{
                     type: :list_item,
                     content: []
                   }
                 ]
               },
               %RichText{
                 type: :table,
                 content: [
                   %RichText{
                     type: :table_row,
                     content: [
                       %RichText{
                         type: :table_header_cell,
                         colspan: 2,
                         rowspan: 3
                       },
                       %RichText{
                         type: :table_cell,
                         colspan: 0,
                         rowspan: 0
                       },
                       %RichText{
                         type: :table_cell,
                         colspan: 4
                       },
                       %RichText{
                         type: :table_cell,
                         rowspan: 5
                       }
                     ]
                   }
                 ]
               },
               %RichText{
                 type: :hyperlink,
                 uri: "http://example.com",
                 content: []
               },
               %RichText{
                 type: :quote,
                 content: []
               },
               %RichText{
                 type: :embedded_entry,
                 target: %Link{store: ^store, type: :entry, id: "entry_id_1", locale: :en}
               },
               %RichText{
                 type: :embedded_asset,
                 target: %Link{store: ^store, type: :asset, id: "asset_id_1", locale: :en}
               },
               %RichText{
                 type: :embedded_entry_inline,
                 content: []
               },
               %RichText{
                 type: :entry_hyperlink,
                 content: []
               },
               %RichText{
                 type: :asset_hyperlink,
                 content: []
               }
             ]
           } = rt
  end

  test "map/2 recursively maps nodes" do
    rt = %RichText{
      type: :document,
      content: [
        %RichText{
          type: :paragraph,
          content: [
            %RichText{
              type: :text,
              value: "Un"
            },
            %RichText{
              type: :text,
              value: "Deux",
              marks: [:bold]
            },
            %RichText{
              type: :text,
              value: "Trois",
              marks: [:italic, :underline, :code]
            }
          ]
        }
      ]
    }

    transformed_rt =
      RichText.map(rt, fn
        %{type: :text, value: "Un"} -> %RichText{type: :text, value: "One"}
        %{marks: [:italic | _]} = node -> %{node | value: "Three, italic!"}
        node -> node
      end)

    assert transformed_rt == %RichText{
             type: :document,
             content: [
               %RichText{
                 type: :paragraph,
                 content: [
                   %RichText{
                     type: :text,
                     value: "One"
                   },
                   %RichText{
                     type: :text,
                     value: "Deux",
                     marks: [:bold]
                   },
                   %RichText{
                     type: :text,
                     value: "Three, italic!",
                     marks: [:italic, :underline, :code]
                   }
                 ]
               }
             ]
           }
  end
end
