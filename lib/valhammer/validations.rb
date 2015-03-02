module Valhammer
  module Validations
    VALHAMMER_DEFAULT_OPTS = { presence: true, uniqueness: true,
                               numericality: true, length: true }.freeze

    VALHAMMER_EXCLUDED_FIELDS = %w(created_at updated_at)

    private_constant :VALHAMMER_DEFAULT_OPTS, :VALHAMMER_EXCLUDED_FIELDS

    def valhammer(opts = {})
      @valhammer_indexes ||= connection.indexes(table_name)
      opts = VALHAMMER_DEFAULT_OPTS.merge(opts)
      columns_hash.each do |name, column|
        valhammer_validate(name, column, opts)
      end
    end

    private

    def valhammer_validate(name, column, opts)
      return if valhammer_exclude?(name)

      assoc = valhammer_assoc(name)
      if assoc && !column.null && opts[:presence]
        return validates(assoc, presence: true)
      end

      validations = valhammer_validations(column, opts)
      validates(name, validations) unless validations.empty?
    end

    def valhammer_validations(column, opts)
      logger.debug("Valhammer generating options for #{valhammer_info(column)}")

      validations = {}
      valhammer_presence(validations, column, opts)
      valhammer_unique(validations, column, opts)
      valhammer_numeric(validations, column, opts)
      valhammer_length(validations, column, opts)

      logger.debug("Valhammer options for #{valhammer_log_key(column)} " \
                   "are: #{validations.inspect}")
      validations
    end

    def valhammer_presence(validations, column, opts)
      return unless opts[:presence]

      validations[:presence] = true unless column.null
    end

    def valhammer_unique(validations, column, opts)
      return unless opts[:uniqueness]

      unique_keys = @valhammer_indexes.select do |i|
        i.unique && i.columns.last == column.name
      end

      return unless unique_keys.one?

      scope = unique_keys.first.columns[0..-2]
      validations[:uniqueness] = scope.empty? ? true : { scope: scope }
    end

    def valhammer_numeric(validations, column, opts)
      return unless opts[:numericality]

      case column.type
      when :integer
        validations[:numericality] = { only_integer: true,
                                       allow_nil: column.null }
      when :decimal
        validations[:numericality] = { only_integer: false,
                                       allow_nil: column.null }
      end
    end

    def valhammer_length(validations, column, opts)
      return unless opts[:length] && column.type == :string && column.limit

      validations[:length] = { maximum: column.limit }
    end

    def valhammer_log_key(column)
      "`#{table_name}`.`#{column.name}`"
    end

    def valhammer_info(column)
      "#{valhammer_log_key(column)} (type=:#{column.type} " \
        "null=#{column.null || 'false'} limit=#{column.limit || 'nil'})"
    end

    def valhammer_exclude?(field)
      field == primary_key || VALHAMMER_EXCLUDED_FIELDS.include?(field)
    end

    def valhammer_assoc(field)
      reflect_on_all_associations(:belongs_to).any? do |assoc|
        return assoc.name if assoc.foreign_key == field
      end
    end
  end
end
