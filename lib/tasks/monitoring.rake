namespace :monitoring do
  desc "Monitoring of the new product in magento shop"
  task new_product: :environment do
    Monitoring::Proccess.new.delay.product
    # Monitoring::Proccess.new.product
  end

end
