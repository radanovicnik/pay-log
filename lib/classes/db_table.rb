module PayLog
  module DbTable
    @@db_table_name = {
      accounts: :v_accounts,
      payments: :v_payments,
      currencies: :currencies
    }

    def self.get_by_id(table, record_id)
      DB[@@db_table_name[table]].first(id: record_id)
    end

    def self.get_all(table, opts = {})
      query = DB[@@db_table_name[table]]

      unless opts[:search_word].to_s.empty?
        case table
        when :accounts
          query = query.where(Sequel.like(:name, "%#{opts[:search_word]}%"))
              .or(Sequel.like(:balance, "#{opts[:search_word]}"))
        when :payments
          query = query.where(Sequel.like(:description, "%#{opts[:search_word]}%"))
              .or(Sequel.like(:amount, "#{opts[:search_word]}"))
              .or(Sequel.like(:from_account, "%#{opts[:search_word]}%"))
              .or(Sequel.like(:to_account, "%#{opts[:search_word]}%"))
        when :currencies
          query = query.where(Sequel.like(:name, "%#{opts[:search_word]}%"))
        end
      end

      case table
      when :accounts, :payments
        query = query.order(Sequel.desc(:created_at))
      when :currencies
        query = query.order(Sequel.desc(:id))
      end

      query.limit(opts[:limit], opts[:offset]).all
    end

    def self.record_to_string(table, record)
      record_str = ''
      return '' if record.to_h.empty?

      case table
      when :accounts
        balance_str = Console.format_money(record[:balance].round(2)) + ' ' + record[:currency]
        record_str = <<~RECORD_STR
          #{record[:name].to_s.bold} (ID #{record[:id]})
          #{record[:balance] >= 0.to_d ? balance_str.green.bold : balance_str.red.bold}
          #{Time.at(record[:created_at]).strftime('%d.%m.%Y. %H:%M')} (created)
          #{Time.at(record[:updated_at]).strftime('%d.%m.%Y. %H:%M')} (updated)

        RECORD_STR
      when :payments
        record_str = <<~RECORD_STR
          [#{Time.at(record[:created_at]).strftime('%d.%m.%Y. %H:%M')}] ID: #{record[:id]}
          #{record[:from_account].to_s.red.bold} #{'->'.bold} #{record[:to_account].to_s.green.bold}
          #{(Console.format_money(record[:amount].round(2)) + ' ' + record[:currency]).bold}
          #{record[:description]}

        RECORD_STR
      when :currencies
        record_str = <<~RECORD_STR
          [#{record[:id]}] #{record[:name].to_s.bold}

        RECORD_STR
      end
      record_str
    end

    def self.field_to_string(name, value)
      if [BigDecimal, Float].include? value.class
        value = Console.format_money(value)
      end

      "#{name.to_s.gsub('_', ' ').capitalize.blue.bold}#{':'.bold} #{value.to_s.green.bold}"
    end

    def self.check_empty_fields(record, fields)
      empty_fields = fields.filter { |k| record[k].nil? }
      unless empty_fields.empty?
        raise ArgumentError.new("There are some empty fields left!\n(#{empty_fields.join(', ')})")
      end
      return nil
    end

    def self.currency_exist?(name)
      !DB[:currencies].where(Sequel.like(:name, name)).empty?
    end

    def self.handle_existing_account(name, currency_id)
      check_record = DB[:accounts]
          .where(Sequel.like(:name, name))
          .where(currency_id: currency_id)
          .first
      unless check_record.nil?
        raise ArgumentError.new("Account \"#{name}\" already exists! (ID: #{check_record[:id]})")
      end
      return nil
    end

    def self.handle_existing_currency(name)
      check_record = DB[:currencies].where(Sequel.like(:name, name)).first
      unless check_record.nil?
        raise ArgumentError.new("Currency \"#{name}\" already exists! (ID: #{check_record[:id]})")
      end
      return nil
    end

    def self.find_or_create_account(name, currency_id)
      record = DB[:accounts]
          .where(Sequel.like(:name, name))
          .where(currency_id: currency_id)
          .first
      id = record.nil? ? nil : record[:id]
      if id.nil?
        id = DB[:accounts].insert(
          name: name,
          currency_id: currency_id
        )
        $db_modified = true
      end
      return id
    end

    def self.find_or_create_currency(name)
      record = DB[:currencies].where(Sequel.like(:name, name)).first
      id = record.nil? ? nil : record[:id]
      if id.nil?
        id = DB[:currencies].insert(name: name)
        $db_modified = true
      end
      return id
    end

    def self.update_account_balance(account_id)
      sent_payments = DB[:payments].select(:amount).where(from_account_id: account_id).all
      received_payments = DB[:payments].select(:amount).where(to_account_id: account_id).all

      account_balance = received_payments.map{|r| r[:amount]}.sum - sent_payments.map{|r| r[:amount]}.sum

      DB[:accounts].where(id: account_id).update(
        balance: account_balance,
        updated_at: Time.now.to_i
      )
      $db_modified = true
    end

    def self.insert(table, record)
      new_record = {}
      new_record_id = nil

      case table
      when :accounts
        check_empty_fields(record, %i(name currency))

        currency_id = find_or_create_currency(record[:currency])

        new_record[:name] = record[:name]
        new_record[:currency_id] = currency_id
        new_balance = record[:balance] || 0.to_d

        # throw exception if trying to insert an existing account
        handle_existing_account(new_record[:name], currency_id)

        DB.transaction do
          new_record_id = DB[:accounts].insert(new_record)

          if new_balance != 0.to_d
            insert(:payments, {
              from_name: (new_balance > 0.to_d) ? DEFAULT_UNKNOWN_ACCOUNT : new_record[:name],
              to_name: (new_balance > 0.to_d) ? new_record[:name] : DEFAULT_UNKNOWN_ACCOUNT,
              currency: record[:currency],
              amount: new_balance.abs,
              description: '[SYSTEM] Setting account balance.'
            })
          end
        end

      when :payments
        check_empty_fields(record, %i(description amount currency from_name to_name))

        currency_id = find_or_create_currency(record[:currency])

        new_record.merge! record.slice(:description, :amount)

        DB.transaction do
          %w(from to).each do |prefix|
            account_name = record[:"#{prefix}_name"]
            account_name = DEFAULT_UNKNOWN_ACCOUNT if account_name.to_s.empty?
            
            new_record[:"#{prefix}_account_id"] = find_or_create_account(account_name, currency_id)
          end

          DB[:accounts].where(id: new_record[:from_account_id]).update(
            balance: Sequel[:balance] - new_record[:amount],
            updated_at: Time.now.to_i
          )
          DB[:accounts].where(id: new_record[:to_account_id]).update(
            balance: Sequel[:balance] + new_record[:amount],
            updated_at: Time.now.to_i
          )
          new_record_id = DB[:payments].insert(new_record)
        end

      when :currencies
        check_empty_fields(record, %i(name))
        new_record[:name] = record[:name]

        # throw exception if trying to insert an existing currency
        handle_existing_currency(new_record[:name])

        DB.transaction do
          new_record_id = DB[:currencies].insert(new_record)
        end
      end

      $db_modified = true
      new_record_id
    end

    def self.update(table, id, record)
      new_data = {}
      updated_count = 0
      old_record = DB[table].first(id: id) || {}
      currency_id = nil

      case table
      when :accounts
        %i(name balance).each do |column|
          if !record[column].nil? && record[column] != old_record[column]
            new_data[column] = record[column]
          end
        end
        new_balance = new_data.delete :balance

        # currency of account is not changeable
        currency_id = old_record[:currency_id]

        # throw exception if trying to rename to existing account
        handle_existing_account(new_data[:name], currency_id) unless new_data[:name].nil?

        DB.transaction do
          unless new_data.empty?
            new_data[:updated_at] = Time.now.to_i
            updated_count = DB[:accounts].where(id: id).update(new_data)
          end

          unless new_balance.nil?
            balance_diff = new_balance - old_record[:balance]
            account_name = new_data[:name] || old_record[:name]
            if balance_diff != 0.to_d
              updated_count = insert(:payments, {
                from_name: (balance_diff > 0.to_d) ? DEFAULT_UNKNOWN_ACCOUNT : account_name,
                to_name: (balance_diff > 0.to_d) ? account_name : DEFAULT_UNKNOWN_ACCOUNT,
                currency: DB[:currencies].first(id: currency_id)[:name],
                amount: balance_diff.abs,
                description: '[SYSTEM] Updating account balance.'
              })
            end
          end
        end

      when :payments
        %i(description amount).each do |column|
          if !record[column].nil? && record[column] != old_record[column]
            new_data[column] = record[column]
          end
        end

        # currency of payment is not changeable
        tmp = DB[:accounts].first(id: [old_record[:from_account_id], old_record[:to_account_id]].compact)
        currency_id = tmp.nil? ? nil : tmp[:currency_id]

        DB.transaction do
          %w(from to).each do |prefix|
            account_name = record[:"#{prefix}_name"]
            account_id = nil
            if !account_name.nil? && !currency_id.nil?
              account_id = find_or_create_account(account_name, currency_id)
            end
            if !account_id.nil? && account_id != old_record[:"#{prefix}_account_id"]
              new_data[:"#{prefix}_account_id"] = account_id
            end
          end
          
          if new_data.slice(:from_account_id, :to_account_id, :amount).any? { |_, v| !v.nil? }
            DB[:accounts].where(id: old_record[:from_account_id]).update(
              balance: Sequel[:balance] + old_record[:amount],
              updated_at: Time.now.to_i
            )
            DB[:accounts].where(id: old_record[:to_account_id]).update(
              balance: Sequel[:balance] - old_record[:amount],
              updated_at: Time.now.to_i
            )

            new_from_id = new_data[:from_account_id] || old_record[:from_account_id]
            new_to_id = new_data[:to_account_id] || old_record[:to_account_id]
            new_amount = new_data[:amount] || old_record[:amount]

            DB[:accounts].where(id: new_from_id).update(
              balance: Sequel[:balance] - new_amount,
              updated_at: Time.now.to_i
            )
            DB[:accounts].where(id: new_to_id).update(
              balance: Sequel[:balance] + new_amount,
              updated_at: Time.now.to_i
            )
          end

          unless new_data.empty?
            new_data[:updated_at] = Time.now.to_i
            updated_count = DB[:payments].where(id: id).update(new_data)
          end
        end

      when :currencies
        if !record[:name].nil? && record[:name] != old_record[:name]
          new_data[:name] = record[:name]
        end

        # throw exception if trying to rename to existing currency
        handle_existing_currency(new_data[:name]) unless new_data[:name].nil?

        DB.transaction do
          unless new_data.empty?
            updated_count = DB[:currencies].where(id: id).update(new_data)
          end
        end
      end

      $db_modified = true
      return updated_count
    end

    def self.delete(table, id, replacement_account = nil)
      deleted_count = 0
      record = DB[table].first(id: id)
      if record.nil?
        raise ArgumentError.new(Content.error_record_missing(table, id))
        return nil
      end

      case table
      when :accounts
        new_account_id = nil

        unless replacement_account.nil?
          tmp = DB[:accounts]
              .where(Sequel.like(:name, replacement_account))
              .where(currency_id: record[:currency_id])
              .first
          replacement_id = tmp.nil? ? nil : tmp[:id]

          if replacement_id.nil?
            raise ArgumentError.new("Replacement account named \"#{replacement_account}\" doesn't exist!")
            return nil
          else
            new_account_id = replacement_id
          end
        else
          new_account_id = find_or_create_account(DEFAULT_UNKNOWN_ACCOUNT, record[:currency_id])
        end

        DB.transaction do
          %w(from to).each do |prefix|
            DB[:payments].where(:"#{prefix}_account_id" => id).update(
              :"#{prefix}_account_id" => new_account_id,
              :updated_at => Time.now.to_i
            )
          end
          deleted_count = DB[:accounts].where(id: id).delete
          update_account_balance(new_account_id)
        end

      when :payments
        DB.transaction do
          DB[:accounts].where(id: record[:from_account_id]).update(
            balance: Sequel[:balance] + record[:amount],
            updated_at: Time.now.to_i
          )
          DB[:accounts].where(id: record[:to_account_id]).update(
            balance: Sequel[:balance] - record[:amount],
            updated_at: Time.now.to_i
          )
          deleted_count = DB[:payments].where(id: id).delete
        end

      when :currencies
        account_ids = DB[:accounts].where(currency_id: id).all.map { |x| x[:id] }
        %w(from to).each do |prefix|
          DB[:payments].where(:"#{prefix}_account_id" => account_ids).delete
        end

        DB[:accounts].where(currency_id: id).delete
        DB[:currencies].where(id: id).delete

      end

      $db_modified = true
      deleted_count
    end
  end
end
