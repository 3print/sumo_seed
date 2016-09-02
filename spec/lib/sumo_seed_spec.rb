require 'spec_helper'
require 'sumo_seed'

describe SumoSeed do

  describe '.run_task' do
    it 'loads the seeds paths from the seed_path' do
      ENV['seed_path'] = ['spec', 'fixtures', 'seeds', 'top_level'].join('/')

      expect { SumoSeed.run_task }.to change { SeoMeta.count }.by 2
    end
  end
end
