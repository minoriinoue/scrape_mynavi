require 'nokogiri'
require 'open-uri'
require 'natto'
require 'csv'
require 'pry'

natto = Natto::MeCab.new
doc = Nokogiri::HTML(open('https://job.rikunabi.com/2017/contents/article/edit~ranking~index/c/'))

gyoukai_to_counters = {} # {gyoukai => {seicho => 4, kaisha => 5, kirakira => 1, kuruma => 3}}
token_to_counters = {} # {seicho => 4, kaisha => 5, kirakira => 1, kuruma => 3}
#i = 0
doc.css('.edit_ranking .hdp-business .edit_ranking-tabContents-list-item a').each do |category|
    category_url = 'https://job.rikunabi.com' << category.attribute('href').value
    gyoukai_name = category.inner_text
    #p category_url
    category_page = Nokogiri::HTML(open(category_url))
    company_links = []
    category_page.css('.mpc-mod-cassette_type03').each do |company|
      company_id = company.attribute('data-kokyakucd').value
      company_url = 'https://job.rikunabi.com/2017/company/employ/' << company_id
      #p company_url
      company_page = Nokogiri::HTML(open(company_url))
      company_page.css('.company-media-sentence').each do |saiyou_kijun|
        saiyou_kijun_content = saiyou_kijun.inner_text
        #p saiyou_kijun_content
        natto.parse(saiyou_kijun_content) do |token_with_analysis|
          feature = token_with_analysis.feature
          splitted = feature.split(",")
          #print splitted
          #binding.pry
          if splitted[0] == "形容詞"
            #binding.pry
            token = token_with_analysis.surface
            if token_to_counters.key?(token)
              token_to_counters[token] += 1
            else
              token_to_counters[token] = 1
            end
          end
        end # end of analysis by Mecab
      end # end of saiyou kijun in a company page
    end # end of company
    gyoukai_to_counters[gyoukai_name] = token_to_counters.dup

    # set all the counters to 0.
    token_to_counters.each do |token, counter|
        token_to_counters[token] = 0
    end
end # end of category

all_data_array = []
header = ["gyoukai"]
header.concat(token_to_counters.keys)
all_data_array << header

#binding.pry

# all_data_array = [ header, [gyoukai_name, counter, counter...], [], []...]
gyoukai_to_counters.each do |gyoukai_name, t_to_c|
    values = [gyoukai_name]
    values.concat(t_to_c.values)
    all_data_array << values
end

# insert 0s so that the length of each array in the array is all same.
length_of_array = all_data_array[0].length
all_data_array[1..all_data_array.length-1].each do |array_in_array|
    length_of_array_in_array = array_in_array.length
    array_in_array.concat(Array.new(length_of_array - length_of_array_in_array,0))
end

#binding.pry
# tokens_to_counters =
#  [[header[0], gyoukai_name_1, gyoukai_name_2, ...],
#   [token(=header[1]), counter(of gyoukai_1), counter(of gyoukai_2),...]
#  ]
tokens_to_counters = all_data_array.transpose
#print tokens_to_counters, "\n"

header_processed = tokens_to_counters[0].dup
header_processed << "sum"
all_data_array_processed = [header_processed]
for token_to_counters in tokens_to_counters[1..(tokens_to_counters.length-1)]
    counter_sum = token_to_counters[1..token_to_counters.length-1].inject {|sum, n| sum + n}
    token_to_counters << counter_sum
    if counter_sum > 1
        all_data_array_processed << token_to_counters.dup
    end
end

#binding.pry
# all_data_array_processed =
#  [[header[0], gyoukai_name_1, gyoukai_name_2, ..., sum],
#   [token(=header[1]), counter(of gyoukai_1), counter(of gyoukai_2),..., sum], ...
#  ]

# sort arrays in array by sum of the counter.
all_data_array_processed_sorted = [header_processed]
last_index = header_processed.length - 1
all_data_array_processed_sorted.concat(all_data_array_processed[1..all_data_array_processed.length-1].sort { |a, b| b[last_index] <=> a[last_index]})

#binding.pry
# final_all_data_array =
#  [[gyoukai, token1(most frequent token), token2, ...],
#   [gyoukai1, counter, counter,...],
#   ....,
#   [sum, sum of frequency of token_1, token_2, ...]
#  ]
final_all_data_array = all_data_array_processed_sorted.transpose
#binding.pry
CSV.open("rikunavi.csv", "a") do |csv|
    final_all_data_array.each do |array|
        csv << array
    end
end
