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
    case table
    when :accounts
      DB[table].insert(
        {}
      )
    when :payments
    end
  end
end
