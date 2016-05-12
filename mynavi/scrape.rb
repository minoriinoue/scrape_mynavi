require 'nokogiri'
require 'open-uri'
require 'natto'
require 'csv'

natto = Natto::MeCab.new
doc = Nokogiri::HTML(open('https://job.mynavi.jp/conts/2017/industry_ranking/?func=PCtop'))

links = {}
category_to_companies = {}
category_to_tokens = {}
doc.css('.rankingBoxInner').each do |category|
    links_2 = {}
    company_to_tokens = {}
    tokens_to_counter_for_category_to_tokens = {}
    gyoukai_name = category.css('.hdg01 h3').inner_text
    category.css('.rankTxt a').each do |link|
        links_2[link.content] = 'https://job.mynavi.jp' << link.attribute('href').value
        # Open the url and analyze words.
        puts links_2[link.content]
        company_page = Nokogiri::HTML(open(links_2[link.content]))
        token_to_numbers = {}

        dengon_ban = company_page.css('.messageArea p').inner_text
        natto.parse(dengon_ban) do |token_with_analysis|
            token = token_with_analysis.surface
            if token_to_numbers.key?(token)
                token_to_numbers[token] += 1
            else
                token_to_numbers[token] = 1
            end

            if tokens_to_counter_for_category_to_tokens.key?(token)
                tokens_to_counter_for_category_to_tokens[token] += 1
            else
                tokens_to_counter_for_category_to_tokens[token] = 1
            end
        end

        profile = company_page.css('.inner > .dataTable p').inner_text
        natto.parse(profile) do |token_with_analysis|
            token = token_with_analysis.surface
            if token_to_numbers.key?(token)
                token_to_numbers[token] += 1
            else
                token_to_numbers[token] = 1
            end

            if tokens_to_counter_for_category_to_tokens.key?(token)
                tokens_to_counter_for_category_to_tokens[token] += 1
            else
                tokens_to_counter_for_category_to_tokens[token] = 1
            end
        end
        tmp = token_to_numbers.sort {|(k1, v1), (k2,v2)| v2 <=> v1}
        company_to_tokens[link.content] = tmp.to_h
    end
    tmp_2 = tokens_to_counter_for_category_to_tokens.sort {|(k1, v1), (k2,v2)| v2 <=> v1}
    category_to_tokens[gyoukai_name] = tmp_2.to_h
    #puts category_to_tokens
    header = ["gyoukai"]
    header.concat(category_to_tokens[gyoukai_name].keys)
    values = [gyoukai_name]
    values.concat(category_to_tokens[gyoukai_name].values)
    CSV.open("gyoukai_to_token.csv", "a") do |csv|
        csv << header
        csv << values
        csv << [" "]
    end
    links[gyoukai_name] = links_2
    category_to_companies[gyoukai_name] = company_to_tokens
end

puts links
puts category_to_companies
