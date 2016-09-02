# :seedling: SumoSeed [![Build Status](https://travis-ci.org/3print/sumo_seed.svg?branch=master)](https://travis-ci.org/3print/sumo_seed)

This project rocks and uses MIT-LICENSE.

Usage:
```ruby
Seeder.new(paths).load
# Or you can
Seeder.new(paths).load do |model_to_create|
 # do something with the model to create
end
```

Seeds are a defined as a collection of hashes in a yaml file.
The seeding task will then iterate over this collection to create a new record
for each unless a model with the same attribute values exist in the database.
By default, all the attribute present in the record hash are used to build the
lookup query.
The seed file must have the same name as the resource, meaning the underscore
pluralized version of the model name.
The seed file can have two format:
* In the first format, the record list is the only content of the seed file:
  ```yaml
  - name: record 1
    some_attribute: some value
  - name: record 2
    some_attribute: some other value
  ```
* In the second format, the record list is stored in a `seeds` key into a
  hash:
  ```yaml
  seeds:
  - name: record 1
    some_attribute: some value
  - name: record 2
    some_attribute: some other value
  ```
  This second form allow to specify some additional options for the seeding
  task.
  The following options are available:
  - `priority`: if you need some model to be seeded before or after some
    other model you can use this setting to change the order in which seeds
    are processed. Higher values appears later.
  - `ignore_in_query`: the list of attribute names to ignore when building
    the lookup query.
  - `use_in_query`: the list of attribute names to use to build the query for
    checking for model existence. If both `ignore_in_query` and `use_in_query`
    are defined, only `use_in_query` will be used.
  - `ignore_unknown_attributes`: When `true` the seed hash will be reaped of
    all the fields that doesn't match a column or an association name.
Some special values can be used for a field to process the attribute content
in some way:
- `_find` - A seed can reference another model for a `belongs_to` association,
  but since we don't know the model id in the seed we'll have to use another
  method to find the record.
  The form is `_find: Class#query` where `query` is a list of tuple of the
  field to match.
  For instance:
  ```yaml
  - name: 'Foo'
    parent:
      _find: ModelClass#field_a=value_a,field_b=value_b
  ```
- `_asset` - Allow to populate an uploader using a file located in the assets
  directory of the project.
  The form is `_asset: relative/path/to/asset`.
- `_eval` - Allow to run a ruby expression and use the returned value for the
  given attribute.
  ```yaml
  - name: 'Foo'
    parent:
      _eval: ModelClass.first
  ```
