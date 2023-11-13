module UniqueNumbers
  class AlphaNumericGenerator < Generator
    ALPHANUMERIC = [*'A'..'Z', *'a'..'z', *'0'..'9']
    store_accessor :settings, :minimum, :maximum, :max_tries, :scope, :exclude_chars

    after_initialize do |generator|
      generator.max_tries ||= 100
    end

    def assign_next_number(model = nil, attribute = nil, exclude_chars = nil, debug = false)
      self.with_lock do
        max_tries.times do
          alphanumric_string = if exclude_chars.present?
                                 SecureRandom.send 'choose', (ALPHANUMERIC - exclude_chars), 5
                               else
                                 SecureRandom.alphanumeric(5)
                               end
          value = (1..9).to_a[rand(9)].to_s + alphanumric_string.upcase
          now = Time.now
          model_scope = model.class.base_class
          case scope
          when :daily
            model_scope = model_scope.where('DATE(created_at) = ?', Date.today)
          end
          if !model_scope.where("#{attribute} ILIKE ?", "#{value}%").exists?
            self.last_generated_at = now
            self.save!
            model.update_columns(attribute => value + format)
            return
          end
        end
        model.errors.add(attribute, "maximum number of generation tries reached")
        raise ActiveRecord::RecordInvalid, model
      end
    end
  end
end
