defmodule CFSyncTest.Integration.SyncConnectorMock.DataInitial do
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
            "id": "ygP74CyESVFcDpJojH0tT",
            "type": "Entry",
            "createdAt": "2022-03-29T10:10:42.301Z",
            "updatedAt": "2022-03-29T10:16:18.686Z",
            "environment": {
              "sys": {
                "id": "master",
                "type": "Link",
                "linkType": "Environment"
              }
            },
            "revision": 4,
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
              "en-US": "My page"
            },
            "integer": {
              "en-US": 7
            },
            "decimal": {
              "en-US": 7
            },
            "date": {
              "en-US": "2022-04-15"
            },
            "datetime": {
              "en-US": "2022-03-29T10:14:51.251Z"
            },
            "location": {
              "en-US": {
                "lon": 0.6853340026449928,
                "lat": 47.3987910198615
              }
            },
            "one_asset": {
              "en-US": {
                "sys": {
                  "type": "Link",
                  "linkType": "Asset",
                  "id": "5m9oC9bksUxeHqVZXuWk8V"
                }
              }
            },
            "many_assets": {
              "en-US": [
                {
                  "sys": {
                    "type": "Link",
                    "linkType": "Asset",
                    "id": "NYNi7JZ7Rp2PnbQgjydEV"
                  }
                },
                {
                  "sys": {
                    "type": "Link",
                    "linkType": "Asset",
                    "id": "1E2XUWOdWpqDIzAWXZGwtj"
                  }
                },
                {
                  "sys": {
                    "type": "Link",
                    "linkType": "Asset",
                    "id": "2pGP9VWr9d2M83TecIJzY0"
                  }
                }
              ]
            },
            "boolean": {
              "en-US": false
            },
            "json": {
              "en-US": {
                "key": "value"
              }
            },
            "one_link": {
              "en-US": {
                "sys": {
                  "type": "Link",
                  "linkType": "Entry",
                  "id": "ygP74CyESVFcDpJojH0tT"
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
                },
                {
                  "sys": {
                    "type": "Link",
                    "linkType": "Entry",
                    "id": "4fy2iBRIRPm20eaViIl0R6"
                  }
                },
                {
                  "sys": {
                    "type": "Link",
                    "linkType": "Entry",
                    "id": "FMeGnbv6ZnP6OqSwQSHMW"
                  }
                },
                {
                  "sys": {
                    "type": "Link",
                    "linkType": "Entry",
                    "id": "41t5pomHIVxPaeF0fadmG1"
                  }
                },
                {
                  "sys": {
                    "type": "Link",
                    "linkType": "Entry",
                    "id": "3hOhfoV5IefhWp2uwq17YW"
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
            "id": "18vvU4uLfjZA409cWC7BJu",
            "type": "Entry",
            "createdAt": "2022-03-29T10:14:51.251Z",
            "updatedAt": "2022-03-29T10:14:51.251Z",
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
              "en-US": "Altaïr"
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
            "updatedAt": "2022-03-29T10:14:37.795Z",
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
              "en-US": "Tarazed"
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
            "updatedAt": "2022-03-29T10:14:23.308Z",
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
            "id": "41t5pomHIVxPaeF0fadmG1",
            "type": "Entry",
            "createdAt": "2022-03-29T10:12:47.904Z",
            "updatedAt": "2022-03-29T10:12:47.904Z",
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
            "id": "3hOhfoV5IefhWp2uwq17YW",
            "type": "Entry",
            "createdAt": "2022-03-29T10:12:38.466Z",
            "updatedAt": "2022-03-29T10:12:38.466Z",
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
            "id": "2pGP9VWr9d2M83TecIJzY0",
            "type": "Asset",
            "createdAt": "2022-03-29T10:09:48.696Z",
            "updatedAt": "2022-03-29T10:09:48.696Z",
            "environment": {
              "sys": {
                "id": "master",
                "type": "Link",
                "linkType": "Environment"
              }
            },
            "revision": 1
          },
          "fields": {
            "title": {
              "en-US": "Four"
            },
            "description": {
              "en-US": ""
            },
            "file": {
              "en-US": {
                "url": "//images.ctfassets.net/diw11gmz6opc/2pGP9VWr9d2M83TecIJzY0/513c26a3064f20728806f5fc2ae28d42/four.jpg",
                "details": {
                  "size": 3644360,
                  "image": {
                    "width": 4000,
                    "height": 6000
                  }
                },
                "fileName": "four.jpg",
                "contentType": "image/jpeg"
              }
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
            "id": "1E2XUWOdWpqDIzAWXZGwtj",
            "type": "Asset",
            "createdAt": "2022-03-29T10:09:17.679Z",
            "updatedAt": "2022-03-29T10:09:17.679Z",
            "environment": {
              "sys": {
                "id": "master",
                "type": "Link",
                "linkType": "Environment"
              }
            },
            "revision": 1
          },
          "fields": {
            "title": {
              "en-US": "Three"
            },
            "description": {
              "en-US": ""
            },
            "file": {
              "en-US": {
                "url": "//images.ctfassets.net/diw11gmz6opc/1E2XUWOdWpqDIzAWXZGwtj/e87f638171f9dd614df704901d4ca5f8/three.jpg",
                "details": {
                  "size": 941805,
                  "image": {
                    "width": 2448,
                    "height": 3676
                  }
                },
                "fileName": "three.jpg",
                "contentType": "image/jpeg"
              }
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
            "id": "NYNi7JZ7Rp2PnbQgjydEV",
            "type": "Asset",
            "createdAt": "2022-03-29T10:08:51.560Z",
            "updatedAt": "2022-03-29T10:08:51.560Z",
            "environment": {
              "sys": {
                "id": "master",
                "type": "Link",
                "linkType": "Environment"
              }
            },
            "revision": 1
          },
          "fields": {
            "title": {
              "en-US": "Two"
            },
            "description": {
              "en-US": ""
            },
            "file": {
              "en-US": {
                "url": "//images.ctfassets.net/diw11gmz6opc/NYNi7JZ7Rp2PnbQgjydEV/5d99df7dd40377e84427553b67032771/two.jpg",
                "details": {
                  "size": 2466898,
                  "image": {
                    "width": 2905,
                    "height": 4357
                  }
                },
                "fileName": "two.jpg",
                "contentType": "image/jpeg"
              }
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
            "id": "5m9oC9bksUxeHqVZXuWk8V",
            "type": "Asset",
            "createdAt": "2022-03-29T10:08:26.748Z",
            "updatedAt": "2022-03-29T10:08:26.748Z",
            "environment": {
              "sys": {
                "id": "master",
                "type": "Link",
                "linkType": "Environment"
              }
            },
            "revision": 1
          },
          "fields": {
            "title": {
              "en-US": "One"
            },
            "description": {
              "en-US": "One asset"
            },
            "file": {
              "en-US": {
                "url": "//images.ctfassets.net/diw11gmz6opc/5m9oC9bksUxeHqVZXuWk8V/852c68b98e8e5383ade431cb8dbef27f/one.jpg",
                "details": {
                  "size": 6568275,
                  "image": {
                    "width": 10235,
                    "height": 8708
                  }
                },
                "fileName": "one.jpg",
                "contentType": "image/jpeg"
              }
            }
          }
        }
      ],
      "nextSyncUrl": "delta_1"
    }
    """
end
