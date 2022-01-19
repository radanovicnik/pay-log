module DbTable
  def self.get_by_id(table, record_id)
    DB[:"v_#{table}"].first(id: record_id)
  end

  def self.record_to_string(table, record)
    record_str = ''
    columns = []
    return '' if record.to_h.empty?
    case table
    when :accounts
      record_str = <<~RECORD_STR
        ID: #{record[:id]}
        Name: #{record[:name]}
        Balance: #{Console.format_money(record[:balance].round(2))} #{record[:currency]}
        Created at: #{Time.at(record[:created_at]).strftime('%d.%m.%Y. %H:%M')}
        Updated at: #{Time.at(record[:updated_at]).strftime('%d.%m.%Y. %H:%M')}

      RECORD_STR
    when :payments
      record_str = <<~RECORD_STR
        [#{Time.at(record[:created_at]).strftime('%d.%m.%Y. %H:%M')}] ID: #{record[:id]}
        From: #{record[:from_account]}
        To: #{record[:to_account]}
        Amount: #{Console.format_money(record[:amount].round(2))} #{record[:currency]}
        Description: #{record[:description]}
        
      RECORD_STR
    end
    record_str
  end

  def self.insert(table, record)
    new_record = {}
    tmp = DB[:currencies].first(Sequel.like(:name, record[:currency]))
    currency_id = tmp.nil? ? nil : tmp[:id]
    new_record_id = nil

    case table
    when :accounts
      new_record.merge! record.slice(:name, :balance)
      new_record[:currency_id] = currency_id

      # throw exception if trying to insert an existing account
      check_record = DB[:accounts]
          .where(Sequel.like(:name, new_record[:name]))
          .where(currency_id: currency_id)
          .first
      unless check_record.nil?
        raise ArgumentError.new('Account already exists!')
        return nil
      end

      new_record_id = DB[:accounts].insert(new_record)

    when :payments
      new_record.merge! record.slice(:description, :amount)
      new_accounts = {}

      %w(from to).each do |prefix|
        account_name = record[:"#{prefix}_name"]
        account_name = DEFAULT_UNKNOWN_ACCOUNT if account_name.to_s.empty?

        tmp = DB[:accounts]
            .where(Sequel.like(:name, account_name))
            .where(currency_id: currency_id)
            .first
        new_record[:"#{prefix}_account_id"] = tmp.nil? ? nil : tmp[:id]

        new_accounts[prefix.to_sym] = account_name if new_record[:"#{prefix}_account_id"].nil?
      end
      
      DB.transaction do
        new_accounts.each do |key, val|
          new_record[:"#{key}_account_id"] = DB[:accounts].insert(
            name: val,
            balance: 0,
            currency_id: currency_id
          )
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
    end

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
      unless new_data[:name].nil?
        check_record = DB[:accounts]
            .where(Sequel.like(:name, new_data[:name]))
            .where(currency_id: currency_id)
            .first
        unless check_record.nil?
          raise ArgumentError.new('Account already exists!')
          return nil
        end
      end

      unless new_data.empty?
        new_data[:updated_at] = Time.now.to_i
        updated_count = DB[:accounts].where(id: id).update(new_data)
      end

      unless new_balance.nil?
        balance_diff = new_balance - old_record[:balance]
        account_name = new_data[:name] || old_record[:name]
        if balance_diff != 0.to_d
          insert(:payments, {
            from_name: (balance_diff > 0.to_d) ? DEFAULT_UNKNOWN_ACCOUNT : account_name,
            to_name: (balance_diff > 0.to_d) ? account_name : DEFAULT_UNKNOWN_ACCOUNT,
            currency: DB[:currencies].first(id: currency_id)[:name],
            amount: balance_diff.abs,
            description: "Manual balance update."
          })
        end
      end

    when :payments
      new_accounts = {}
      %i(description amount).each do |column|
        if !record[column].nil? && record[column] != old_record[column]
          new_data[column] = record[column]
        end
      end

      # currency of payment is not changeable
      tmp = DB[:accounts].first(id: [old_record[:from_account_id], old_record[:to_account_id]].compact)
      currency_id = tmp.nil? ? nil : tmp[:currency_id]
      
      %w(from to).each do |prefix|
        account_name = record[:"#{prefix}_name"]

        if !account_name.nil? && !currency_id.nil?
          tmp = DB[:accounts]
              .where(Sequel.like(:name, account_name))
              .where(currency_id: currency_id)
              .first
          account_id = tmp.nil? ? nil : tmp[:id]

          if !account_id.nil? && account_id != old_record[:"#{prefix}_account_id"]
            new_data[:"#{prefix}_account_id"] = account_id
          elsif account_id.nil?
            new_accounts[prefix.to_sym] = account_name
          end
        end
      end

      unless new_data.empty?
        DB.transaction do
          new_accounts.each do |key, val|
            new_data[:"#{key}_account_id"] = DB[:accounts].insert(
              name: val,
              balance: 0,
              currency_id: currency_id
            )
          end
          
          unless new_data[:amount].nil?
            amount_diff = new_data[:amount] - old_record[:amount]
            DB[:accounts].where(id: new_data[:from_account_id] || old_record[:from_account_id]).update(
              balance: Sequel[:balance] - amount_diff,
              updated_at: Time.now.to_i
            )
            DB[:accounts].where(id: new_data[:to_account_id] || old_record[:to_account_id]).update(
              balance: Sequel[:balance] + amount_diff,
              updated_at: Time.now.to_i
            )
          end

          new_data[:updated_at] = Time.now.to_i
          updated_count = DB[:payments].where(id: id).update(new_data)
        end
      end
    end

    return updated_count
  end
end
