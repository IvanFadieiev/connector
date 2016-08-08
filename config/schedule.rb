# Learn more: http://github.com/javan/whenever


every 1.days :at => '4:30 am' do 
    rake "monitoring:new_product"
end