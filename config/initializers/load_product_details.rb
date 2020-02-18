# Load Current year & Next Year Products
start_year = Date.today.year
end_year = start_year + 1

$rates = {}

def quarter(val)
  (val / 3.0).ceil
end

::Products::Product.where(
  :"application_period.min".gte => Date.new(start_year, 1, 1), :"application_period.max".lte => Date.new(end_year, 1, 1).end_of_year
).each do |product|
  product.premium_tables.each do |pt|
    output = pt.premium_tuples.inject({}) do |result, tuple|
      result[tuple.age] = tuple.cost
      result
    end
    (quarter(pt.effective_period.min.month)..quarter(pt.effective_period.max.month)).each do |q|
      $rates[[product.id, pt.rating_area_id, q]] = {entries: output, max_age: product.premium_ages.max, min_age: product.premium_ages.min}
    end
  end
end


$sic_factors = {}

Products::ActuarialFactors::SicActuarialFactor.all.where(:"active_year".in => [start_year, end_year]).each do |factor|
  factor.actuarial_factor_entries.each do |entry|
    $sic_factors[[entry.factor_key, factor.active_year, factor.issuer_hios_id]] = entry.factor_value
  end
end
