# frozen_string_literal: true

def parse_text(cell)
  cell.blank? ? nil : sanitize_value(cell)
end

def sanitize_value(value)
  value = value.to_s.split('.')[0] if value.is_a? Float
  value.gsub(/[[:cntrl:]]|^\p{Space}+|\p{Space}+$/, '')
end

Rails.logger.debug ':: Started Creating SBC documents ::'

roster = Roo::Spreadsheet.open(ENV.fetch('sbc_path', nil))
sheet = roster.sheet(0)
columns = sheet.row(1)

output = (2..sheet.last_row).each_with_object([]) do |id, result|
  row = [columns, sheet.row(id)].transpose.to_h

  result << {
    product_name: parse_text(row['product_name']),
    hios_id: parse_text(row['hios_id']),
    year: parse_text(row['year']).to_i,
    identifier: parse_text(row['identifier']),
    title: parse_text(row['title'])
  }
end

count = 0
output.each do |info|
  product = Products::Product.where(
    :hios_id => info[:hios_id],
    :'application_period.min'.gte => Date.new(info[:year], 1, 1),
    :'application_period.max'.lte => Date.new(info[:year], 1, 1).end_of_year
  ).first

  if product.blank?
    Rails.logger.debug { "No product for #{info[:hios_id]} #{info[:year]}" }
    next
  end
  product.title = info[:product_name]

  product.sbc_document = Documents::Document.new({ title: info[:title], subject: 'SBC', format: 'application/pdf',
                                                   identifier: info[:identifier] })
  product.save
  count += 1

  Rails.logger.debug { "Product #{product.title} #{product.hios_id} updated, uri #{product.sbc_document.identifier}" } unless Rails.env.test?
end
Rails.logger.debug { "Total #{count} plans/products updated." } unless Rails.env.test?

Rails.logger.debug ':: Created SBC documents ::'
