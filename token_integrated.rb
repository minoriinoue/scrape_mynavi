require 'nokogiri'
require 'open-uri'
require 'natto'
require 'csv'
require 'pry'

natto = Natto::MeCab.new
doc = Nokogiri::HTML(open('https://job.mynavi.jp/conts/2017/industry_ranking/?func=PCtop'))

gyoukai_to_counters = {} # {gyoukai => {seicho => 4, kaisha => 5, kirakira => 1, kuruma => 3}}
token_to_counters = {} # {seicho => 4, kaisha => 5, kirakira => 1, kuruma => 3}
doc.css('.rankingBoxInner').each do |category|
    gyoukai_name = category.css('.hdg01 h3').inner_text
    category.css('.rankTxt a').each do |link|
        company_url = 'https://job.mynavi.jp' << link.attribute('href').value
        # Open the url and analyze words.
        puts company_url
        company_page = Nokogiri::HTML(open(company_url))

        dengon_ban = company_page.css('.messageArea p').inner_text
        natto.parse(dengon_ban) do |token_with_analysis|
            feature = token_with_analysis.feature
            splitted = feature.split(",")
            #print splitted
            #binding.pry
            if splitted[0] == "名詞"
                #binding.pry
                token = token_with_analysis.surface
                if token_to_counters.key?(token)
                    token_to_counters[token] += 1
                else
                    token_to_counters[token] = 1
                end
            end
            #binding.pry
        end

        profile = company_page.css('.inner > .dataTable p').inner_text
        natto.parse(profile) do |token_with_analysis| 
            feature = token_with_analysis.feature
            splitted = feature.split(",")
            #binding.pry
            if splitted[0] == "名詞"
                token = token_with_analysis.surface
                if token_to_counters.key?(token)
                    token_to_counters[token] += 1
                else
                    token_to_counters[token] = 1
                end
            end
        end
    end # end of each company url.
    gyoukai_to_counters[gyoukai_name] = token_to_counters.dup

    # set all the counters to 0.
    token_to_counters.each do |token, counter|
        token_to_counters[token] = 0
    end
end # end of each gyoukai

header = ["gyoukai"]
header.concat(token_to_counters.keys)
CSV.open("header_integrated.csv", "a") do |csv|
    csv << header
    gyoukai_to_counters.each do |gyoukai_name, t_to_c|
        values = [gyoukai_name]
        values.concat(t_to_c.values)
        csv << values
    end
end
