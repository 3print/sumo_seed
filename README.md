# :seedling: SumoSeed [![Build Status](https://travis-ci.org/3print/sumo_seed.svg?branch=master)](https://travis-ci.org/3print/sumo_seed)

## Usage

To use the Sümo seeder through the `rake db:seed` task you'll need to to clear and then redefine the seed task in a `lib/tasks/seed.rake` file with the following content:

```ruby
require 'sumo_seed'

Rake::Task["db:seed"].clear

namespace :db do
  task seed: :environment do
    SumoSeed.run_task
  end
end
```

This will invoke the SumoSeed task when running `rake db:seed`. By default the task will look in the `db/seeds` directory of your app for seed files.

Seeds are a defined as a collection of hashes in one or more yaml files.

The following directory structures are possible and can be mixed together:

#### One file for a single model
```
seeds
|__ models.yml
```

##### models.yml

A typical seed file, with config on top and then the models in the `seeds` array.

```yaml
use_in_query:
- name
prioriy: 1
seeds:
- name: Dummy Seed 1
  description: lorem ipsum
- name: Dummy Seed 2
  description: lorem ipsum
```

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

#### Several files for a single model

##### .seeds.yml

In that case, the `.seed.yml` file should contains the model's seed configuration. The other files contain one or more seeds.  
```
seeds
|__ models
    |__ .seed.yml
    |__ file-a.yml
    |__ file-b.yml
```

##### file-a.yml

```yaml
name: Dummy Seed
description: A single seed in a file. No need to use an array for that.
```

##### file-b.yml

```yaml
- name: Dummy Seed 1
  description: Several seeds in the same file.
- name: Dummy Seed 2
  description: An array is therefore necessary.
```

### Using the Seeder class directly

It's also possible to instanciate a `Seeder` object directly with a list of paths to process:

```ruby
Seeder.new(paths, options).load
# Or you can
Seeder.new(paths, options).load do |model_to_create|
  # do something with the model to create
end
```

## Seed Files

As described above, seed files can be organized in many ways. Both ways are compatible and can be used together. In case the seed config is present both in the main seed file and in a `.seed.yml` file the settings from both files will be merged.

The seeds themselves are collected and stored in a single array, the seeding task will then iterate over this collection to create a new record
for each unless a model with the same attribute values exist in the database.

By default, all the attribute present in the record hash are used to build the
lookup query. It can be changed using the `use_in_query` and `ignore_in_query` settings.

### Seed Files Settings

|Setting|Description|
|-------|-----------|
|`env`|If specified the seed file will only apply to the corresponding Rails environments. This setting must be a list of environments. This setting can also be specified on each seed separately|
|`priority`|If you need some model to be seeded before or after some other model you can use this setting to change the order in which seeds are processed. Higher values appears later.|
|`ignore_in_query`|The list of attribute names to ignore when building the lookup query.|
|`use_in_query`|the list of attribute names to use to build the query for checking for model existence. If both `ignore_in_query` and `use_in_query` are defined, only `use_in_query` will be used.|
|`ignore_unknown_attributes`|When `true` the seed hash will be reaped of all the fields that doesn't match a column or an association name.|

### Special Attributes Values

Some special values can be used for a field to process the attribute content
in some way

##### `_find`

A seed can reference another model for a `belongs_to` association, but since we don't know the model id in the seed we'll have to use another method to find the record.
The form is `_find: Class#query` where `query` is a list of tuple of the field to match.

For instance:

```yaml
- name: 'Foo'
  parent:
    _find: ModelClass#field_a=value_a,field_b=value_b
```
##### `_asset`

Allow to populate an uploader using a file located in the assets directory of the project.

The form is `_asset: relative/path/to/asset`.

```yaml
- name: 'Foo'
  image:
    _asset: path/to/asset.jpg
```

##### `_eval`

Allow to run a ruby expression and use the returned value for the given attribute.

```yaml
- name: 'Foo'
  parent:
    _eval: ModelClass.first
```
