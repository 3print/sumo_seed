require 'seeder'

module SumoSeed
  def self.seed_path
    [Rails.root, 'db', 'seeds']
  end

  def self.run_task
    seed_path = [Rails.root, ENV['seed_path'].split('/')].flatten || self.seed_path
    model_collection = ENV['model'] || '*'
    models_collection = ENV['models'] ? ENV['models'].split(',') : [model_collection]
    upsert = ENV['upsert'] == '1'

    dirs = models_collection.map {|pattern|
      seed_dir_pattern = File.join(*(seed_path + [pattern]))
      if pattern != '*'
        seed_file_pattern = File.join(*(seed_path + ["#{pattern}.yml"]))
        Dir[seed_file_pattern] + Dir[seed_dir_pattern]
      else
        Dir[seed_dir_pattern]
      end
    }.flatten.uniq

    Seeder.new(dirs, upsert: upsert).load

    if model_collection == 'stores'
      Store.all.each { |s| s.create_default_pages! }
    end
  end
end
