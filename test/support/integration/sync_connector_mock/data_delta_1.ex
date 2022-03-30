defmodule CFSyncTest.Integration.SyncConnectorMock.DataDelta1 do
  def payload,
    do: """
    {
      "sys": {
        "type": "Array"
      },
      "items": [
        {
          "sys": {
            "type": "DeletedEntry",
            "id": "4fy2iBRIRPm20eaViIl0R6",
            "space": {
              "sys": {
                "type": "Link",
                "linkType": "Space",
                "id": "diw11gmz6opc"
              }
            },
            "environment": {
              "sys": {
                "id": "master",
                "type": "Link",
                "linkType": "Environment"
              }
            },
            "revision": 1,
            "createdAt": "2022-03-29T10:30:14.573Z",
            "updatedAt": "2022-03-29T10:30:14.573Z",
            "deletedAt": "2022-03-29T10:30:14.573Z"
          }
        },
        {
          "sys": {
            "type": "DeletedEntry",
            "id": "3hOhfoV5IefhWp2uwq17YW",
            "space": {
              "sys": {
                "type": "Link",
                "linkType": "Space",
                "id": "diw11gmz6opc"
              }
            },
            "environment": {
              "sys": {
                "id": "master",
                "type": "Link",
                "linkType": "Environment"
              }
            },
            "revision": 1,
            "createdAt": "2022-03-29T10:30:14.573Z",
            "updatedAt": "2022-03-29T10:30:14.573Z",
            "deletedAt": "2022-03-29T10:30:14.573Z"
          }
        },
        {
          "sys": {
            "type": "DeletedEntry",
            "id": "FMeGnbv6ZnP6OqSwQSHMW",
            "space": {
              "sys": {
                "type": "Link",
                "linkType": "Space",
                "id": "diw11gmz6opc"
              }
            },
            "environment": {
              "sys": {
                "id": "master",
                "type": "Link",
                "linkType": "Environment"
              }
            },
            "revision": 1,
            "createdAt": "2022-03-29T10:30:14.573Z",
            "updatedAt": "2022-03-29T10:30:14.573Z",
            "deletedAt": "2022-03-29T10:30:14.573Z"
          }
        },
        {
          "sys": {
            "type": "DeletedEntry",
            "id": "41t5pomHIVxPaeF0fadmG1",
            "space": {
              "sys": {
                "type": "Link",
                "linkType": "Space",
                "id": "diw11gmz6opc"
              }
            },
            "environment": {
              "sys": {
                "id": "master",
                "type": "Link",
                "linkType": "Environment"
              }
            },
            "revision": 1,
            "createdAt": "2022-03-29T10:30:14.573Z",
            "updatedAt": "2022-03-29T10:30:14.573Z",
            "deletedAt": "2022-03-29T10:30:14.573Z"
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
            "id": "ygP74CyESVFcDpJojH0tT",
            "type": "Entry",
            "createdAt": "2022-03-29T10:10:42.301Z",
            "updatedAt": "2022-03-29T10:29:59.689Z",
            "environment": {
              "sys": {
                "id": "master",
                "type": "Link",
                "linkType": "Environment"
              }
            },
            "revision": 5,
            "contentType": {
              "sys": {
                "type": "Link",
                "linkType": "ContentType",
                "id": "page"
              }
            }
          },
          "fields": {
            "name": {
              "en-US": "Your page"
            },
            "integer": {
              "en-US": 1
            },
            "decimal": {
              "en-US": 1.2
            },
            "date": {
              "en-US": "2022-04-16T00:00+02:00"
            },
            "location": {
              "en-US": {
                "lon": -4.478240216105007,
                "lat": 48.41505184610145
              }
            },
            "one_asset": {
              "en-US": {
                "sys": {
                  "type": "Link",
                  "linkType": "Asset",
                  "id": "2pGP9VWr9d2M83TecIJzY0"
                }
              }
            },
            "many_assets": {
              "en-US": [
                {
                  "sys": {
                    "type": "Link",
                    "linkType": "Asset",
                    "id": "2pGP9VWr9d2M83TecIJzY0"
                  }
                },
                {
                  "sys": {
                    "type": "Link",
                    "linkType": "Asset",
                    "id": "NYNi7JZ7Rp2PnbQgjydEV"
                  }
                }
              ]
            },
            "boolean": {
              "en-US": true
            },
            "json": {
              "en-US": {
                "other_key": "other_value"
              }
            },
            "one_link": {
              "en-US": {
                "sys": {
                  "type": "Link",
                  "linkType": "Entry",
                  "id": "6MQquyPNj1ccczUYRzM7Ky"
                }
              }
            },
            "many_links": {
              "en-US": [
                {
                  "sys": {
                    "type": "Link",
                    "linkType": "Entry",
                    "id": "18vvU4uLfjZA409cWC7BJu"
                  }
                }
              ]
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
            "id": "6MQquyPNj1ccczUYRzM7Ky",
            "type": "Entry",
            "createdAt": "2022-03-29T10:29:45.177Z",
            "updatedAt": "2022-03-29T10:29:45.177Z",
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
              "en-US": "Denebola"
            }
          }
        }
      ],
      "nextSyncUrl": "delta_2"
    }
    """
end
