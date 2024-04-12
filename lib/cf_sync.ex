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
  # Define your fields mappings, one per content-type
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

  # Define a mapping to map Contentful "contentType" ids to an atom name and a fields struct:
  entries_mapping = %{
    # "page" key is the content_type ID as configured in Contentful
    "page" => %{
      content_type: :page,
      fields_module: MyApp.PageFields,
    },
    "author" => %{
      content_type: :author,
      fields_module: MyApp.AuthorFields,
    }
    # ...
  }

  # Start a CFSync process
  {:ok, pid} =
    CFSync.start_link(
      MyApp.MyCFSync,
      "Your_contentful_space_id",
      "Your_contentful_delivery_api_token",
      entries_mapping
    )



  # Use it
  store = CFSync.from(MyApp.MyCFSync)
  entry =  CFSync.get_entry(store, "entry_id")

  # entry ->
    %CFSync.Entry{
      id: "entry_id",
      content_type: :page,
      space_id: "your_space_id",
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
  - `content_types` is a map describing how to map Contentful entries to elixir structs. See module doc.

  ## Options
  - `:locale` - The locale you want to fetch from Contentful. Defaults to `"en-US"`
  - `:root_url` - Default is `"https://cdn.contentful.com/"`
  - `:initial_sync_interval` - The server will wait for this interval between two page
  requests during initial sync. Defaults to 30 milliseconds.
  - `:delta_sync_interval` - The server will wait for this interval between two sync
  requests. Defaults to 5000 milliseconds. You can use a shorter delay to get updates
  faster, but you will be rate limited by Contentful if you set it too short.
  - `:invalidation_callbacks` - List of 0-arity anonymous functions that will
  be called after each sync operation that actually adds, updates or deletes some entries.

  """
  @spec start_link(atom, String.t(), String.t(), map, keyword) ::
          :ignore | {:error, any} | {:ok, pid}
  def start_link(name, space_id, delivery_token, content_types, opts)
      when is_atom(name) and
             is_binary(space_id) and
             is_binary(delivery_token) and
             is_list(opts),
      do: Store.start_link(name, space_id, delivery_token, content_types, opts)

  @doc """
  Forces the store for `name` to sync immediately. Use the name you provided to `start_link/4`.

  CFSync regularly synces entries from Contentful API (see `start_link/4`).
  Calling this function triggers an immediate sync and resets the timer for the
  next regular sync, so it will only happen after the full delay (`:delta_sync_interval`)
  counting from the immediate sync.

  You can use Contentful `publish` and `unpublish`
  [webhooks](https://www.contentful.com/developers/docs/concepts/webhooks/)
  to trigger calls to this function in order to achieve almost instant
  synchronisation. You can then relax `:delta_sync_interval` in the configuration
  to lower the number of API requests made to Contentful.

  ```
  CFSync.force_sync(MyApp.MyCFSync)
  ```
  """
  @spec force_sync(atom) :: :ok
  def force_sync(name), do: Store.force_sync(name)

  @doc """
  Get the CFSync store for `name`. Use the name you provided to `start_link/4`.

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

  @doc """
  Resolves a `link` (child entry or asset) from an entry field and returns the corresponding asset or entry.

  Returns `nil` if the child entry or asset is not found.
  """
  @spec get_child(Entry.t(), atom()) :: nil | Entry.t() | Asset.t()
  def get_child(%Entry{} = entry, field_name) when is_atom(field_name) do
    link = Map.fetch!(entry.fields, field_name)
    get_link_target(entry.store, link)
  end

  @doc """
  Resolves a list of `link` (children entries or assets) from an entry field and returns the corresponding assets or entries.

  Returns the list of links mapped to the corresponding assets or entries.
  If an entry or asset is not found, it will be mapped to `nil`.
  """
  @spec get_children(Entry.t(), atom()) :: [nil | Entry.t() | Asset.t()]
  def get_children(%Entry{} = entry, field_name) when is_atom(field_name) do
    entry.fields
    |> Map.fetch!(field_name)
    |> Enum.map(&get_link_target(entry.store, &1))
  end

  @doc """
  Phoenix.Component that renders RichText.

  You can pass these assigns:
  - content: the %RichText{} struct to render
  - class: a class attribute that will be added to root element of rendered HTML
  - delegate: a module with custom components to use for rendering

  Delegate and class are optional.
  To use delegate module, see RichTextRenderer and RichTextRendererTest modules
  """
  @spec rich_text(map) :: Phoenix.LiveView.Rendered.t()
  def rich_text(assigns), do: CFSync.RichTextRenderer.render(assigns)
end
