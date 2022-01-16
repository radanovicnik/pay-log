module DbTable
  def self.get_by_id(table, record_id)
    DB["v_#{table}".to_sym].first(id: record_id)
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
      new_record.merge! record.filter{|k, _| %i(name balance).include?(k)}
      new_record[:currency_id] = currency_id

      new_record_id = DB[:accounts].insert(new_record)

    when :payments
      new_record.merge! record.filter{|k, _| %i(description amount).include?(k)}
      new_accounts = {}

      %w(from to).each do |prefix|
        account_name = record["#{prefix}_name".to_sym]
        account_name = DEFAULT_UNKNOWN_ACCOUNT if account_name.to_s.empty?

        tmp = DB[:accounts]
          .where(Sequel.like(:name, account_name))
          .where(currency_id: currency_id)
          .first
        new_record["#{prefix}_account_id".to_sym] = tmp.nil? ? nil : tmp[:id]

        new_accounts[prefix.to_sym] = account_name if new_record["#{prefix}_account_id".to_sym].nil?
      end
      
      DB.transaction do
        new_accounts.each do |key, val|
          new_record["#{key}_account_id".to_sym] = DB[:accounts].insert(
            name: val,
            balance: 0,
            currency_id: currency_id
          )
        end
        DB[:accounts].where(id: new_record[:from_account_id]).update(balance: Sequel[:balance] - new_record[:amount])
        DB[:accounts].where(id: new_record[:to_account_id]).update(balance: Sequel[:balance] + new_record[:amount])
        new_record_id = DB[:payments].insert(new_record)
      end
    end

    new_record_id
  end

  def self.update(table, id, record)
  end
end
