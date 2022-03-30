defmodule CFSync do
  @moduledoc ~S"""
  CFSync is an Elixir client for
  [Contentful sync API](https://www.contentful.com/developers/docs/concepts/sync/).

  ## Features

  - Provides functions to extract field values from Contentful entries JSON payloads.
  - Maps Contenful entries, assets, and links to Elixir structs. Using structs is better for readability,
  performance and reliability.
  - Maps RichText data to Elixir structs.
  - Keeps a cache of your entries and assets in a ETS table.
  This allows for fast (way faster than rest API calls) and concurrent reads.
  - Keeps this cache up to date by regularly fetching changes from Contentful sync API

  ## Installation
  Add `:cf_sync` to your `mix.exs` dependencies.
  ```
  def deps do
  [
    {:cf_sync, "~> 0.1.0"},
  ]
  end
  ```

  ## Basic usage
  ```
  # Define your mappings, one per content-type
  defmodule MyApp.PageFields do
    @behaviour CFSync.Entry.Fields
    import CFSync.Entry.Extractors

    defstruct :name, :body, :author

    # See CFSync.Entry.Extractors for extract_* documentation
    def new(data) do
      %__MODULE__{
        name: extract_binary(data, "name"),
        body: extract_richtext(data, "body"),
        author: extract_link(data, "author"),
      }
    end
  end

  # Setup your content-types in config.exs
  config :cf_sync, :fields_modules, %{
    page: MyApp.PageFields,
    author: MyApp.AuthorFields,
    # ...
  }

  # Start a CFSync process
  {:ok, pid} =
    CFSync.start_link(
      MyApp.MyCFSync,
      "Your_contentful_space_id",
      "Your_contentful_delivery_api_token"
    )



  # Use it
  store = CFSync.from(MyApp.MyCFSync)
  entry =  CFSync.get_entry(store, "entry_id")

  # entry ->
    %CFSync.Entry{
      id: "entry_id",
      content_type: :page,
      fields: %MyApp.PageFields{
        name: "Lorem ipsum",
        body: %CFSync.RichText{ #... },
        author: %CFSync.Link{
          id: "autor_id",
          #... },
        # ...
      }
    }

  author = CFSync.get_link_target(store, entry.fields.author)

  # author ->
    %CFSync.Entry{
      id: "author_id",
      content_type: :author,
      fields: %MyApp.AuthorFields{
        # ...
      }
    }
  ```
  > !! Put your API token and space_id in your ENV, NOT in your code.

  > You should start the CFSync process in a
  > [supervision tree](https://elixir-lang.org/getting-started/mix-otp/supervisor-and-application.html).
  """
  alias CFSync.Store
  alias CFSync.Entry
  alias CFSync.Asset
  alias CFSync.Link

  @typedoc """
  Reference to a CFSync store.
  """
  @opaque store() :: :ets.tid()

  @doc """
  Starts CFSync GenServer

  Should be started in a supervision tree
  - `name` is an atom to reference this CFSync process. Use the same `name`
  in `from/1` to query entries.
  - `space_id` is your Contentful space's ID
  - `delivery_token` is your Contentful API token

  ## Options
  - `:locale` - The locale you want to fetch from Contentful. Defaults to `"en-US"`
  - `:root_url` - Default is `"https://cdn.contentful.com/"`
  - `initial_sync_interval` - The server will wait for this interval between two page
  requests during initial sync. Defaults to 30 milliseconds.
  - `delta_sync_interval` - The server will wait for this interval between two sync
  requests. Defaults to 5000 milliseconds. You can use a shorter delay to get updates
  faster, but you will be rate limited by Contentful if you set it too short.

  """
  @spec start_link(atom, String.t(), String.t(), keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(name, space_id, delivery_token, opts)
      when is_atom(name) and
             is_binary(space_id) and
             is_binary(delivery_token) and
             is_list(opts),
      do: Store.start_link(name, space_id, delivery_token, opts)

  @doc """
  Get the CFSync store for `name`. Use the name your provided to `start_link/4`.

  ```
  store = CFSync.from(MyApp.MyCFSync)
  get_entries(store)
  get_entry(store, "an_entry_id")
  # ...
  ```
  """
  @spec from(atom) :: store()
  def from(name), do: Store.Table.get_table_reference_for_name(name)

  @doc """
  Returns a list containg all entries from the CFSync store `store`.

  This function will retrieve ALL entries currently stored in the store's ETS table
  and deep copy them to the current process. Using this on a large Contentful space
  will be slow. If you want to retrieve all the entries to filter them,
  consider using something like [memoize](https://hexdocs.pm/memoize/Memoize.html)
  to cache the results.
  """
  @spec get_entries(store()) :: [Entry.t()]
  def get_entries(store) when not is_atom(store), do: Store.Table.get_entries(store)

  @doc """
  Returns a list containg all entries of specified `content_type` from the CFSync store `store`.

  See `get_entries/1` about performance.
  """
  @spec get_entries_for_content_type(store(), atom) :: [Entry.t()]
  def get_entries_for_content_type(store, content_type)
      when not is_atom(store) and is_atom(content_type),
      do: Store.Table.get_entries_for_content_type(store, content_type)

  @doc """
  Get the entry specified by `id` from the CFSync store `store`.
  """
  @spec get_entry(store(), binary) :: nil | Entry.t()
  def get_entry(store, id) when not is_atom(store) and is_binary(id),
    do: Store.Table.get_entry(store, id)

  @doc """
  Returns a list containg all assets from the CFSync store `store`.

  See `get_entries/1` about performance.
  """
  @spec get_assets(store()) :: [Asset.t()]
  def get_assets(store) when not is_atom(store), do: Store.Table.get_assets(store)

  @doc """
  Get the asset specified by `id` from the CFSync store `store`.

  Returns `nil` if the asset is not found.
  """
  @spec get_asset(store(), binary) :: nil | Asset.t()
  def get_asset(store, id) when not is_atom(store) and is_binary(id),
    do: Store.Table.get_asset(store, id)

  @doc """
  Resolves `link` in the CFSync store `store` and returns the corresponding asset or entry.

  Returns `nil` if link target is not not found.
  """
  @spec get_link_target(store(), Link.t()) :: nil | Entry.t() | Asset.t()
  def get_link_target(store, %Link{} = link) when not is_atom(store),
    do: Store.Table.get_link_target(store, link)
end
