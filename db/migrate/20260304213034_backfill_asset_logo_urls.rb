class BackfillAssetLogoUrls < ActiveRecord::Migration[8.1]
  PARQET_LOGO_URL = "https://assets.parqet.com/logos/symbol/%s"
  COINGECKO_LOGO_URL = "https://assets.coingecko.com/coins/images/%s/small/%s.png"
  COINGECKO_IMAGE_IDS = {
    "BTC" => [ 1, "bitcoin" ], "ETH" => [ 279, "ethereum" ], "SOL" => [ 4128, "solana" ],
    "ADA" => [ 975, "cardano" ], "DOT" => [ 12171, "polkadot" ], "DOGE" => [ 5, "dogecoin" ],
    "AVAX" => [ 12559, "avalanche-2" ], "LINK" => [ 877, "chainlink" ], "UNI" => [ 12504, "uniswap" ]
  }.freeze

  def up
    Asset.where(logo_url: nil).find_each do |asset|
      logo = case asset.asset_type
      when "crypto"
               ids = COINGECKO_IMAGE_IDS[asset.symbol.upcase]
               ids ? format(COINGECKO_LOGO_URL, ids[0], ids[1]) : nil
      when "fixed_income", "index"
               nil
      else
               asset.country == "MX" ? nil : format(PARQET_LOGO_URL, asset.symbol)
      end

      asset.update_column(:logo_url, logo) if logo
    end
  end

  def down
    # No-op: logos are harmless to keep
  end
end
