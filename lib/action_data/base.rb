class Base
  @joinable_models = {}
  @displayable_fields = {}
  @groupable_fields = {}
  @aggregatable_fields = {}

  class << self
    def model_class
      model_name = self.name.gsub('ActionData', '')
      model_name.constantize
    end

    def joinable_models
      @joinable_models ||= {}
    end

    def joinable_with(other_model, by:)
      joinable_models[self.name] ||= {}
      joinable_models[self.name][other_model] = Array(by)
    end

    def can_join_with?(other_model)
      joinable_models[self.name]&.key?(other_model)
    end

    def join_columns_for(other_model)
      joinable_models[self.name]&.[](other_model)
    end

    def displayable_fields(*fields)
      @displayable_fields ||= {}
      @displayable_fields[self.name] ||= []
      @displayable_fields[self.name].concat(fields)
    end

    def groupable_fields(*fields)
      @groupable_fields ||= {}
      @groupable_fields[self.name] ||= []
      @groupable_fields[self.name].concat(fields)
    end

    def aggregatable_fields(aggregations)
      @aggregatable_fields ||= {}
      @aggregatable_fields[self.name] ||= {}
      @aggregatable_fields[self.name].merge!(aggregations)
    end

    def can_display_field?(field)
      @displayable_fields[self.name]&.include?(field.to_sym)
    end

    def can_group_by?(field)
      @groupable_fields[self.name]&.include?(field.to_sym)
    end

    def can_aggregate?(field, operation)
      @aggregatable_fields[self.name]&.dig(field.to_sym)&.include?(operation.to_sym)
    end

    def alias_field(table_name, field)
      "#{table_name}.#{field} AS \"#{table_name}-#{field}\""
    end

    def raw_field(table_name, field)
      "#{table_name}.#{field}"
    end

    def generate_query(query_params, aggregate: [])
      query = nil
      last_model_class = nil
      group_by_fields = []

      query_params.each do |(action_data_class, fields)|
        model_class = action_data_class.model_class

        fields_with_table = fields.map { |field| alias_field(model_class.table_name, field) }

        if query.nil?
          query = model_class.select(fields_with_table)
        else
          join_columns = last_model_class.join_columns_for(action_data_class.name)
          query = query.joins("INNER JOIN #{model_class.table_name} ON #{last_model_class.model_class.table_name}.#{join_columns.first} = #{model_class.table_name}.id")
          query = query.select(fields_with_table)
        end

        group_by_fields.concat(fields.map { |field| raw_field(model_class.table_name, field) })

        last_model_class = action_data_class
      end

      group_by_fields.uniq!

      group_by_fields.each do |field|
        query = query.group(field)
      end

      aggregate.each do |(action_data_class, aggregations)|
        model_class = action_data_class.model_class

        aggregations.each do |field, operation|
          aggregate_field = raw_field(model_class.table_name, field)
          unless action_data_class.can_aggregate?(field, operation)
            raise "Cannot aggregate #{operation} on #{field} for model #{action_data_class.name}"
          end
          query = query.select("#{operation.upcase}(#{aggregate_field}) AS \"#{model_class.table_name}-#{operation}-#{field}\"")
        end
      end

      ActiveRecord::Base.connection.select_all(query.to_sql).to_a
    end
  end
end
