# Typesensual

Typesensual is a small wrapper around the [Typesense Ruby client][typesense-gem] which provides a
more familiar, rubyish interface for interacting with [Typesense][typesense-website]. Similar to
[Chewy][chewy-gem], it provides a DSL for defining your schema, manages the life-cycle of your
collections, and provides a simple interface for indexing, searching, and deleting documents.

Unlike Chewy, it does *not* handle loading, denormalizing, or formatting your data for search
purposes. It can be combined with an ORM such as ActiveRecord or Sequel, or even used with plain SQL
queries, but that integration is left to you. This is a concious decision, since loading and
transforming data is often a complex and application-specific task that is best left to the
application developer, since you know best.

[typesense-gem]: https://github.com/typesense/typesense-ruby
[typesense-website]: https://typesense.org/
[chewy-gem]: https://github.com/toptal/chewy

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'typesensual'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install typesensual

## Usage

### Configuring the client

The first step is to configure the client. This is done by calling `Typesensual.configure` and
passing a block to configure your parameters:

```ruby
# config/initializers/typesensual.rb
Typesensual.configure do |config|
  # The nodes in your cluster to connect to
  config.nodes = [{ host: 'localhost', port: 8108, protocol: 'http' }]
  # The API key to use for authentication
  config.api_key = 'xyz'
  # The environment you are running in (in Rails, this is set automatically)
  config.env = 'test'
end
```

Alternatively you can configure with env variables:

```env
TYPESENSUAL_NODES=http://node1:8108,http://node2:8108,http://node3:8108
TYPESENSUAL_API_KEY=xyz
TYPESENSUAL_ENV=test
```

### Creating your first index

Once the client is configured, you can create your first index. This is done by creating a subclass
of `Typesensual::Index` and defining your schema and how to load the data. For example, the
following index might be used to index movies from an ActiveRecord model:

```ruby
# app/indices/movies_index.rb
class MoviesIndex < Typesensual::Index
  # The schema of the collection
  schema do
    enable_nested_fields

    field 'title', type: 'string'
    field 'release_date\..*', type: 'int32', facet: true
    field 'average_rating', type: 'float', facet: true
    field 'user_count', type: 'int32'
    field 'genres', type: 'string[]', facet: true
  end

  def index(ids)
    Movies.where(id: ids).includes(:genres).find_each do |movie|
      yield {
        id: movie.id,
        title: movie.title,
        release_date: {
          year: movie.release_date.year,
          month: movie.release_date.month,
          day: movie.release_date.day
        },
        average_rating: movie.average_rating,
        user_count: movie.user_count,
        genres: movie.genres.map(&:name)
      }
    end
  end
end
```

### Integrating with your model

If you use ActiveRecord, there's a set of premade callbacks you can use:

```ruby
class Movie < ApplicationRecord
  after_commit MoviesIndex.ar_callbacks, on: %i[create update destroy]
end
```

You're free to use these callbacks as-is, or you can use them as a starting point for your own
integration. They're just calling `MoviesIndex.index_one` and `MoviesIndex.remove_one` under the
hood, so you can do the same in your own callbacks or outside of ActiveRecord.

### Loading data into your index

Once you have defined your index, you can load data into it and update the alias to point to the
indexed data. Typesensual provides rake tasks for this purpose if you use ActiveRecord:

```console
$ bundle exec rake typesensual:reindex[MoviesIndex,Movie]
==> Reindexing Movie into MoviesIndex (Version 1690076097)
```

Otherwise you can do similar to the following:

```ruby
collection = MoviesIndex.create!
collection.index_many(Movie.ids, collection: collection)
MoviesIndex.update_alias(collection)
```

### Searching your index

Now that you have data in your index, you can search it! Typesensual provides a simple interface for
this purpose, including pagination support:

```ruby
query = MoviesIndex.search(query: 'Your Name', query_by: 'title')
query.per(10).page(2).load
```

The full interface for this is documented in the `Search`, `Results`, and `Hit` classes.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports, feature requests, and pull requests are welcome on [our GitHub][github].

[github]: https://github.com/hummingbird-me/typesensual

## License

The gem is available as open source under the terms of the [MIT License][mit-license].

[mit-license]: https://opensource.org/licenses/MIT
