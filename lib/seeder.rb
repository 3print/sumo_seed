require 'colorize'

class Seeder
  attr_accessor :paths
  attr_accessor :seeds
  attr_accessor :options

  def initialize(paths, options={})
    self.paths = paths
    self.options = options.reverse_merge({
      asset_path: File.join(Rails.root, 'app', 'assets'),
    })
  end

  def load
    all_seeds.each do |seeds_settings|
      model_class = seeds_settings[:class]
      seeds = seeds_settings[:seeds]
      ignores = seeds_settings[:ignore_in_query] || []
      base_scope = seeds_settings[:base_scope].present? ? eval(seeds_settings[:base_scope]) : model_class
      uses = seeds_settings[:find_by] || seeds_settings[:use_in_query] || []

      output "\n#{model_class}\n"

      seeds.each do |seed|
        env = seed.delete(:env)

        next if env.present? && !env.include?(Rails.env)

        if seeds_settings[:ignore_unknown_attributes]
          seed = cleanup_attributes(model_class, seed)
        end

        seed = process_attributes(seed)

        query = as_query(model_class, seed, ignores, uses)
        begin
          unless model = find_existing_seed(base_scope, query)
            ActiveRecord::Base.transaction do
              model = model_class.new(seed)
              yield model if block_given?
              model.save!
            end
            output created(model)
          else
            if options[:upsert]
              ActiveRecord::Base.transaction do
                seed.each_pair do |k,v|
                  begin
                    model.send("#{k}=", v) if model.send(k) != v
                  rescue => e
                    print e.backtrace.join("\n")
                    print "\n"
                    raise
                  end
                end
                yield model if block_given?
                model.save!
              end
              if model.previous_changes.empty?
                output existing(model)
              else
                output modified(model)
              end
            else
              output existing(model)
            end
          end
        rescue => e
          if model.present?
            output failed(model, e)
          else
            raise e
          end
        end
      end
    end
  end

  def find_existing_seed(model_class, query)
    filter_resources(model_class).where(query).first
  end

  def filter_resources(model_class)
    model_class
  end

  def all_seeds
    self.seeds ||= paths.map do |f|
      model_class = File.basename(f, '.yml').classify.constantize

      if File.directory?(f)
        paths = Dir[File.join(f, '**/*.yml')]

        config = paths.select {|f| File.basename(f, '.yml') == 'config' }.first
        paths.reject! {|f| f == config }

        settings = load_file(config).with_indifferent_access


        settings[:seeds] = paths.map {|ff|
          seed = load_seed(ff, model_class)
          seed[:seeds].present? ? seed[:seeds] : seed
        }.compact.flatten
      else
        settings = load_seed(f, model_class)
      end

      if settings[:seeds].blank?
        raise "empty seeds for #{model_class}"
      end

      env = settings[:env]
      settings[:file] = f
      settings[:ignore_in_query] ||= []
      settings[:class] = model_class
      env.present? && !env.include?(Rails.env) ? nil : settings

    end.compact.sort {|a,b| (a[:priority] || 0) - (b[:priority] || 0) }
  end

  def load_seed(f, model_class)
    settings = load_file(f)

    case
    when settings.is_a?(Hash)
      settings = settings.with_indifferent_access
    when settings.is_a?(Array)
      settings = { seeds: settings }
    else
      raise "invalid seeds type for #{model_class}"
    end

    settings
  end

  def load_file(f)
    begin
      YAML.load_file(f)
    rescue => e
      "#{"Can't load file".light_black} #{f.red}"
      raise e
    end
  end

  def as_query(model_class, seed, ignores, uses)
    belongs_to_associations = association_columns(model_class, :belongs_to)
    polymorphic_belongs_to_associations = polymorphic_association_columns(model_class)
    query = seed.dup

    if uses.present?
      query = Hash[query.select {|k,v| uses.include?(k) }]
    else
      ignores.each { |i| query.delete(i) }
    end

    Hash[query.map do |k,v|
      if belongs_to_associations.include?(k)
        ["#{k}_id", v.try(:id)]
      elsif polymorphic_belongs_to_associations.include?(k)
        [
          ["#{k}_id", v.try(:id)],
          ["#{k}_type", v.try(:class).try(:name)]
        ]
      elsif model_class.defined_enums.has_key?(k)
        [k, model_class.send(k.to_s.pluralize)[v]]
      else
        [k, v]
      end
    end].symbolize_keys
  end

  def cleanup_attributes(model_class, attrs)
    instance = model_class.new

    Hash[attrs.select { |k,v| instance.respond_to?(:"#{k}=") }].with_indifferent_access
  end

  def process_attributes(attrs)
    Hash[attrs.map do |k,v|
      if v.is_a?(Hash)
        v = process_attribute_value(v)
      elsif v.is_a?(Array)
        v = v.map {|vv| vv.is_a?(Hash) ? process_attribute_value(vv) : vv }
      end

      [k,v]
    end]
  end

  def process_attribute_value(v)
    if v.has_key?(:_find)
      m,t = v[:_find].split('#')
      l = t.split(',')
      q = {}
      l.each do |ll|
        a,vv = ll.split('=')
        q[a] = vv
      end

      v = filter_resources(m.constantize).where(q).first
    elsif v.has_key?(:_asset)
      v = File.open(resolve_img_path v[:_asset])
    elsif v.has_key?(:_eval)
      v = eval(v[:_eval])
    else
      process_attributes(v)
    end
  end

  def association_columns(object, *by_associations)
    if object.respond_to?(:reflections)
      object.reflections.collect do |name, association_reflection|
        if by_associations.present?
          if by_associations.include?(association_reflection.macro) && association_reflection.options[:polymorphic] != true
            name.to_s
          end
        else
          name.to_s
        end
      end.compact
    else
      []
    end
  end

  def polymorphic_association_columns(object)
    if object.respond_to?(:reflections)
      object.reflections.collect do |name, association_reflection|
        if association_reflection.options[:polymorphic]
          name.to_s
        end
      end.compact
    else
      []
    end
  end

  def content_columns(object)
    return [] unless object.respond_to?(:content_columns)
    object.content_columns.collect { |c| c.name }.compact
  end

  def all_columns(object)
    content_columns(object) + association_columns(object)
  end

  def resolve_img_path(img)
    File.expand_path(img, options[:asset_path]).to_s
  end

  def resource_label_for(resource)
    self.class.resource_label_for(resource)
  end

  def output(msg)
    self.class.output(msg)
  end

  def created(model)
    self.class.created(model)
  end

  def modified(model)
    self.class.modified(model)
  end

  def existing(model)
    self.class.existing(model)
  end

  def failed(model, e)
    self.class.failed(model, e)
  end

  def self.resource_label_for(resource)
    label = nil
    %w(title caption name localized_name).each do |k|
      label ||= resource.try(k)
    end
    label = resource.to_s if label.nil?
    label
  end

  def self.output(msg)
    print msg unless Rails.env.test?
  end

  def self.created(model)
    [
      ' ',
      '+'.green,
      resource_label_for(model).green,
      "created successfully\n".light_black
    ].join(' ')
  end

  def self.modified(model)
    [
      ' ',
      '●'.green,
      resource_label_for(model).green,
      "modified successfully\n".light_black
    ].join(' ')
  end

  def self.existing(model)
    [
      ' ',
      '○'.yellow,
      resource_label_for(model),
      "already existed\n".light_black
    ].join(' ')
  end

  def self.failed(model, e=nil)
    msg = [
      [
        ' ',
        '✕'.red,
        resource_label_for(model),
        "didn't validate".light_black
      ].join(' ')
    ]

    if model.errors.any?
      msg << "\n    "
      msg << model.errors.messages.map do |k,v|
        ["#{k}:".red, v.first.to_s.light_black].join(' ')
      end.join("\n    ")
    else
      msg << "\n    "
      msg << e.backtrace.join("\n    ")
    end

    msg.join('') + "\n"
  end
end
