module Mode
  @@states = %w(
    menu new edit delete list help
  )

  def self.change(name)
    name = name.strip
    if @@states.include? name
      name
    else
      raise ArgumentError.new('Invalid state name!')
      return nil
    end
  end

  def self.all
    @@states
  end
end