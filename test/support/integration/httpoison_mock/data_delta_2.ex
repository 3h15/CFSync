defmodule CFSyncTest.Integration.HTTPoisonMock.DataDelta2 do
  def payload,
    do: """
    {
      "sys": {
        "type": "Array"
      },
      "items": [
        {
          "metadata": {
            "tags": []
          },
          "sys": {
            "space": {
              "sys": {
                "type": "Link",
                "linkType": "Space",
                "id": "diw11gmz6opc"
              }
            },
            "id": "4MvXPwlHRUiuJyNSI9MXnv",
            "type": "Entry",
            "createdAt": "2022-03-29T10:34:56.990Z",
            "updatedAt": "2022-03-29T10:34:56.990Z",
            "environment": {
              "sys": {
                "id": "master",
                "type": "Link",
                "linkType": "Environment"
              }
            },
            "revision": 1,
            "contentType": {
              "sys": {
                "type": "Link",
                "linkType": "ContentType",
                "id": "page"
              }
            }
          },
          "fields": {}
        },
        {
          "metadata": {
            "tags": []
          },
          "sys": {
            "space": {
              "sys": {
                "type": "Link",
                "linkType": "Space",
                "id": "diw11gmz6opc"
              }
            },
            "id": "13klSU54KfXYbdHKetuEHV",
            "type": "Entry",
            "createdAt": "2022-03-29T10:33:11.324Z",
            "updatedAt": "2022-03-29T10:33:11.324Z",
            "environment": {
              "sys": {
                "id": "master",
                "type": "Link",
                "linkType": "Environment"
              }
            },
            "revision": 1,
            "contentType": {
              "sys": {
                "type": "Link",
                "linkType": "ContentType",
                "id": "star"
              }
            }
          },
          "fields": {
            "name": {
              "en-US": "Spica"
            }
          }
        },
        {
          "metadata": {
            "tags": []
          },
          "sys": {
            "space": {
              "sys": {
                "type": "Link",
                "linkType": "Space",
                "id": "diw11gmz6opc"
              }
            },
            "id": "3hOhfoV5IefhWp2uwq17YW",
            "type": "Entry",
            "createdAt": "2022-03-29T10:12:38.466Z",
            "updatedAt": "2022-03-29T10:32:43.840Z",
            "environment": {
              "sys": {
                "id": "master",
                "type": "Link",
                "linkType": "Environment"
              }
            },
            "revision": 2,
            "contentType": {
              "sys": {
                "type": "Link",
                "linkType": "ContentType",
                "id": "star"
              }
            }
          },
          "fields": {
            "name": {
              "en-US": "Deneb"
            }
          }
        },
        {
          "metadata": {
            "tags": []
          },
          "sys": {
            "space": {
              "sys": {
                "type": "Link",
                "linkType": "Space",
                "id": "diw11gmz6opc"
              }
            },
            "id": "41t5pomHIVxPaeF0fadmG1",
            "type": "Entry",
            "createdAt": "2022-03-29T10:12:47.904Z",
            "updatedAt": "2022-03-29T10:32:43.819Z",
            "environment": {
              "sys": {
                "id": "master",
                "type": "Link",
                "linkType": "Environment"
              }
            },
            "revision": 2,
            "contentType": {
              "sys": {
                "type": "Link",
                "linkType": "ContentType",
                "id": "star"
              }
            }
          },
          "fields": {
            "name": {
              "en-US": "Eltanin"
            }
          }
        },
        {
          "metadata": {
            "tags": []
          },
          "sys": {
            "space": {
              "sys": {
                "type": "Link",
                "linkType": "Space",
                "id": "diw11gmz6opc"
              }
            },
            "id": "FMeGnbv6ZnP6OqSwQSHMW",
            "type": "Entry",
            "createdAt": "2022-03-29T10:14:23.308Z",
            "updatedAt": "2022-03-29T10:32:43.763Z",
            "environment": {
              "sys": {
                "id": "master",
                "type": "Link",
                "linkType": "Environment"
              }
            },
            "revision": 2,
            "contentType": {
              "sys": {
                "type": "Link",
                "linkType": "ContentType",
                "id": "star"
              }
            }
          },
          "fields": {
            "name": {
              "en-US": "Capella"
            }
          }
        },
        {
          "metadata": {
            "tags": []
          },
          "sys": {
            "space": {
              "sys": {
                "type": "Link",
                "linkType": "Space",
                "id": "diw11gmz6opc"
              }
            },
            "id": "4fy2iBRIRPm20eaViIl0R6",
            "type": "Entry",
            "createdAt": "2022-03-29T10:14:37.795Z",
            "updatedAt": "2022-03-29T10:32:43.734Z",
            "environment": {
              "sys": {
                "id": "master",
                "type": "Link",
                "linkType": "Environment"
              }
            },
            "revision": 2,
            "contentType": {
              "sys": {
                "type": "Link",
                "linkType": "ContentType",
                "id": "star"
              }
            }
          },
          "fields": {
            "name": {
              "en-US": "Tarazed"
            }
          }
        }
      ],
      "nextSyncUrl": "delta_3"
    }
    """
end
