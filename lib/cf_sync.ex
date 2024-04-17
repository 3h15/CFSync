defmodule CFSync do
  @moduledoc ~S"""
  CFSync is an Elixir client for
  [Contentful sync API](https://www.contentful.com/developers/docs/concepts/sync/).

  ## Features

  - Provides functions to extract field values from Contentful entries JSON payloads.
  - Maps Contenful entries, assets, and links to Elixir structs. Using structs is better for readability,
  performance and reliability.
  - Works with a single or multiple locales.
  - Maps RichText data to Elixir structs.
  - Keeps a cache of your entries and assets in a ETS table.
  This allows for fast (way faster than REST API calls) and concurrent reads.
  - Keeps this cache up to date by regularly fetching changes from Contentful sync API

  ## Installation
  Add `:cf_sync` to your `mix.exs` dependencies.
  ```
  def deps do
  [
    {:cf_sync, "~> 0.15.0"},
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
  content_types = %{
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

  # Define your locales (optional):
  locales = %{en: "en-US", fr: "fr-FR"}

  # If you have a single locale, but it is not "en-US", you can use:
  # locales = %{nil: "fr-FR"}

  # Start a CFSync process
  {:ok, pid} =
    CFSync.start_link(
      name: MyApp.MyCFSync,
      space_id: "Your_contentful_space_id",
      delivery_token: "Your_contentful_delivery_api_token",
      content_types: content_types,
      locales: locales
    )



  # Use it
  store = CFSync.from(MyApp.MyCFSync)
  entry =  CFSync.get_entry(store, "entry_id")

  # OR, with multiple locales:
  # entry_fr =  CFSync.get_entry(store, "entry_id", :fr)
  # entry_en =  CFSync.get_entry(store, "entry_id", :en)

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

  author = CFSync.get_link_target(entry.fields.author)
  # Or
  # author = CFSync.get_child(entry, :author)

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
  @type store() :: :ets.tid()

  @doc """
  Starts CFSync GenServer

  Should be started in a supervision tree

  ## Options

  - `name` (required) is an atom to reference this CFSync process. Use the same `name`
  in `from/1` to query entries.
  - `space_id` (required) is your Contentful space's ID
  - `delivery_token` (required) is your Contentful API token
  - `content_types` (required) is a map describing how to map Contentful entries to elixir structs. See module doc.
  - `locales` (optional) is a map of locales. The key is the locale name in Elixir (an atom), the value is the locale name in Contentful.
  - `:root_url` (optional) - Default is `"https://cdn.contentful.com/"`
  - `:initial_sync_interval` (optional) - The server will wait for this interval between two page
  requests during initial sync. Defaults to 30 milliseconds.
  - `:delta_sync_interval` (optional) - The server will wait for this interval between two sync
  requests. Defaults to 5000 milliseconds. You can use a shorter delay to get updates
  faster, but you will be rate limited by Contentful if you set it too short.
  - `:invalidation_callbacks` (optional) - List of 0-arity anonymous functions that will
  be called after each sync operation that actually adds, updates or deletes some entries.

  """
  @spec start_link(keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts), do: Store.start_link(opts)

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
  Returns a list containg all entries for a given `locale` from the CFSync store `store`.

  The `locale` is optional and defaults to `nil`. By default, CFSync is configured to
  work with a single locale (the `nil` locale), which is `en-US`. You can change the default
  locale by passing `locales: %{nil: "fr-FR"}` to `start_link/1`.

  If you have multiple locales, you must pass the locale to this function to get entries
  for that locale.

  This function will retrieve ALL entries currently stored in the store's ETS table
  and deep copy them to the current process. Using this on a large Contentful space
  will be slow. If you want to retrieve all the entries to filter them,
  consider using something like [memoize](https://hexdocs.pm/memoize/Memoize.html)
  to cache the results.
  """
  @spec get_entries(store(), atom) :: [Entry.t()]
  def get_entries(store, locale \\ nil) when not is_atom(store),
    do: Store.Table.get_entries(store, locale)

  @doc """
  Returns a list containg all entries of specified `content_type` for a given
  `locale` from the CFSync store `store`.

  See `get_entries/1` about performance and locale.
  """
  @spec get_entries_for_content_type(store(), atom, atom) :: [Entry.t()]
  def get_entries_for_content_type(store, content_type, locale \\ nil)
      when not is_atom(store) and is_atom(content_type),
      do: Store.Table.get_entries_for_content_type(store, content_type, locale)

  @doc """
  Get the entry specified by `id` for the given locale from the CFSync store `store`.

  Returns `nil` if the entry is not found.

  See `get_entries/1` about locale.
  """
  @spec get_entry(store(), binary, atom) :: nil | Entry.t()
  def get_entry(store, id, locale \\ nil) when not is_atom(store) and is_binary(id),
    do: Store.Table.get_entry(store, id, locale)

  @doc """
  Returns a list containg all assets from the CFSync store `store`.

  See `get_entries/1` about performance and locale.
  """
  @spec get_assets(store(), atom) :: [Asset.t()]
  def get_assets(store, locale \\ nil) when not is_atom(store),
    do: Store.Table.get_assets(store, locale)

  @doc """
  Get the asset specified by `id` for the given locale from the CFSync store `store`.

  Returns `nil` if the asset is not found.

  See `get_entries/1` about locale.
  """
  @spec get_asset(store(), binary, atom) :: nil | Asset.t()
  def get_asset(store, id, locale \\ nil) when not is_atom(store) and is_binary(id),
    do: Store.Table.get_asset(store, id, locale)

  @doc """
  Resolves `link` in the CFSync store `store` and returns the corresponding asset or entry.

  Returns `nil` if link target is not not found.
  """
  @spec get_link_target(Link.t()) :: nil | Entry.t() | Asset.t()
  def get_link_target(%Link{} = link),
    do: Store.Table.get_link_target(link)

  @doc """
  Resolves a `link` (child entry or asset) from an entry field and returns the corresponding asset or entry.

  Returns `nil` if the child entry or asset is not found.
  """
  @spec get_child(Entry.t(), atom()) :: nil | Entry.t() | Asset.t()
  def get_child(%Entry{} = entry, field_name) when is_atom(field_name) do
    entry.fields
    |> Map.fetch!(field_name)
    |> get_link_target()
  end

  @doc """
  Resolves a list of `link` (children entries or assets) from an entry field and returns the corresponding assets or entries.

  Returns the list of links mapped to the corresponding assets or entries.
  If an entry or asset is not found, it is not included in the result.
  """
  @spec get_children(Entry.t(), atom()) :: [nil | Entry.t() | Asset.t()]
  def get_children(%Entry{} = entry, field_name) when is_atom(field_name) do
    entry.fields
    |> Map.fetch!(field_name)
    |> Enum.map(&get_link_target/1)
    |> Enum.filter(&is_map/1)
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
