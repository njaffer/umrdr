module SubjectService
  mattr_accessor :authority
  self.authority = Qa::Authorities::Local.subauthority_for('subject')

  def self.select_options
    authority.all.map do |element|
      [element[:label], element[:id]]
    end
  end

  def self.label(id)
    authority.find(id).fetch('term')
  end
end
