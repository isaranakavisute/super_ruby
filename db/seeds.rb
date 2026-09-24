# Test data for the shop. Safe to run more than once: bin/rails db:seed

# Demo login (username: admin, password: admin). Not created in production, where
# such an easy-to-guess account would let anyone on the internet sign in.
unless Rails.env.production?
  User.find_or_initialize_by(username: "admin").update!(email_address: "admin@example.com", password: "admin")
end

# name, category, emoji, price, original price (nil = not on sale), rating, sold, location
[
  [ "Wireless Bluetooth Earbuds with Noise Cancelling", "Electronics", "🎧", 599, 1290, 4.8, 12_500, "Bangkok" ],
  [ "Fast Charging USB-C Cable 1m (2 Pack)", "Electronics", "🔌", 89, 199, 4.7, 48_300, "Nonthaburi" ],
  [ "Smart Watch Fitness Tracker, Heart Rate Monitor", "Electronics", "⌚", 890, 1590, 4.6, 5_210, "Bangkok" ],
  [ "20000mAh Power Bank, Dual USB", "Electronics", "🔋", 459, nil, 4.8, 9_870, "Samut Prakan" ],
  [ "Mechanical Gaming Keyboard RGB Backlit", "Electronics", "⌨️", 1_190, 1_890, 4.7, 2_140, "Bangkok" ],
  [ "1080p Webcam with Microphone", "Electronics", "📷", 690, nil, 4.5, 1_320, "Chiang Mai" ],

  [ "Oversized Cotton T-Shirt, Unisex", "Fashion", "👕", 159, 290, 4.8, 31_000, "Bangkok" ],
  [ "Slim Fit Stretch Jeans", "Fashion", "👖", 399, nil, 4.6, 7_450, "Bangkok" ],
  [ "Canvas Sneakers, Classic Low Top", "Fashion", "👟", 490, 890, 4.7, 11_200, "Pathum Thani" ],
  [ "Floral Summer Dress", "Fashion", "👗", 359, 590, 4.7, 4_680, "Bangkok" ],
  [ "UV Protection Sunglasses", "Fashion", "🕶️", 129, nil, 4.4, 6_020, "Chonburi" ],

  [ "Memory Foam Pillow, Ergonomic", "Home & Living", "🛏️", 349, 690, 4.8, 8_760, "Nonthaburi" ],
  [ "Aroma Diffuser with LED Night Light", "Home & Living", "🕯️", 299, nil, 4.6, 3_410, "Bangkok" ],
  [ "Non-Stick Frying Pan 28cm", "Home & Living", "🍳", 459, 790, 4.7, 5_930, "Samut Sakhon" ],
  [ "Foldable Storage Box, Set of 3", "Home & Living", "📦", 199, nil, 4.5, 14_800, "Bangkok" ],
  [ "Indoor Potted Plant, Snake Plant", "Home & Living", "🪴", 159, nil, 4.9, 2_270, "Chiang Mai" ],

  [ "Vitamin C Brightening Serum 30ml", "Beauty", "🧴", 259, 450, 4.8, 22_600, "Bangkok" ],
  [ "Matte Liquid Lipstick, Long Lasting", "Beauty", "💄", 149, 250, 4.7, 18_900, "Bangkok" ],
  [ "Sunscreen SPF50+ PA++++ 50ml", "Beauty", "☀️", 199, nil, 4.9, 35_400, "Nonthaburi" ],
  [ "Hydrating Sheet Mask (10 Pieces)", "Beauty", "🧖", 99, 199, 4.6, 27_300, "Bangkok" ],

  [ "Non-Slip Yoga Mat 6mm", "Sports", "🧘", 329, 590, 4.7, 6_540, "Bangkok" ],
  [ "Adjustable Dumbbells Set 10kg", "Sports", "🏋️", 890, nil, 4.6, 1_980, "Pathum Thani" ],
  [ "Official Size Football", "Sports", "⚽", 390, nil, 4.5, 3_120, "Khon Kaen" ],
  [ "Insulated Water Bottle 1L", "Sports", "🥤", 199, 350, 4.8, 15_700, "Bangkok" ],

  [ "Thai Jasmine Rice 5kg", "Groceries", "🍚", 189, nil, 4.9, 42_100, "Suphan Buri" ],
  [ "Roasted Arabica Coffee Beans 250g", "Groceries", "☕", 259, 320, 4.8, 8_430, "Chiang Rai" ],
  [ "Instant Tom Yum Noodles (Pack of 10)", "Groceries", "🍜", 65, nil, 4.7, 56_800, "Bangkok" ],
  [ "Dried Mango Snack 500g", "Groceries", "🥭", 139, 180, 4.8, 12_900, "Chachoengsao" ],
  [ "Mixed Nuts, Unsalted 400g", "Groceries", "🥜", 229, nil, 4.6, 4_360, "Bangkok" ],
  [ "Organic Honey 350g", "Groceries", "🍯", 179, 240, 4.9, 3_050, "Chiang Mai" ]
].each do |name, category, emoji, price, original_price, rating, sold_count, location|
  Product.find_or_initialize_by(name: name).update!(
    category: category, emoji: emoji, price: price, original_price: original_price,
    rating: rating, sold_count: sold_count, location: location
  )
end
