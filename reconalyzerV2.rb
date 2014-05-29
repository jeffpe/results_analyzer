# Recon
# The next time I do this use SQL or someting like that. This is getting ridiculous.



# load in the required libraries
require "csv"
require "date"

# set the names of the csv files
pp_file_name = "paypal_recon.csv"
sf_file_name = "salesforce_recon.csv"
output_file_name = "recon_output.csv"
# set the parameters of the paypal csv file. First line/field = 0 
pp_start_line = 8
pp_transid_field = 14
pp_amt_field = 8

# set the parameters of the salesforce csv file. Testing globals to see how they work.
@sf_start_line = 1
@sf_transid_field = 0
@sf_amt_field = 8 #formerly 1
@sf_account_field = 2
@sf_product_field = 4
@sf_error_list = []
@hi_yearly_amt = 799
@hrm_yearly_amt = 2499

# final output variables
in_pp_not_sf = {}
in_sf_not_pp = {}
diff_amt_list = {}
@paypal_total = 0
@salesforce_total = 0
@hi_yearly_count = 0
@hrm_yearly_count = 0

# Convert CSV to ARRAY, input csv_name, return the array
def csv_to_array(csv_name)
	CSV.read(csv_name)
end

# PayPal CSV has an annoying set of 3 characters at the start of the file in some weird encoding that crashes the Ruby CSV library. This zaps them. The characters covert to "n++" if you mess with them but come out as jibberish in Ruby. If you hand parse each line of the csv you could also exclude them using gsub, but that's a waste of time.
def scrub_pp_csv(csv_name)
	IO.write(csv_name, '"XXX', 0)
end

#Hash the PP CSV TranactionID => Amt. ignore negative line items and zero amts. No nils are present in PP reports.
def make_pp_hash(pp_array, pp_start_line, pp_length, pp_transid_field, pp_amt_field)
	the_hash={}
	for i in (pp_start_line..(pp_length-1))

		transaction_id = pp_array[i][pp_transid_field]
		transaction_amt = pp_array[i][pp_amt_field]
		transaction_amt = transaction_amt.delete(",") 			#get rid of the comma in the string
		transaction_amt_f=transaction_amt.to_f					#now you can convert the string to floating point
	
		if transaction_amt_f > 0											#we don't look at negative transactions because salesforce only records positives. Go figure.
			the_hash[transaction_id]=transaction_amt_f
			@paypal_total += transaction_amt_f
		end
	end
	return the_hash
end

#Hash the SF file  the Sum of TranactionIDs => Amt, but watch out for nils, trials, and zeros
def make_sf_hash(sf_array)
# hash the salesforce file. Could also make methods/cases off of the cases of the content of transaction id. Also testing this globle type variables
	sf_hash={}
	product_amt_hash={}
	for i in (@sf_start_line..(@sf_length-6))
	
		
		transaction_id = sf_array[i][@sf_transid_field]
		transaction_amt = sf_array[i][@sf_amt_field]
		if transaction_amt != nil
			transaction_amt = transaction_amt.delete(",")  #note: if the amt is nil this fails. Hence the need for this IF statement. Note nils are not the same as zeros in our SF reporting.
			transaction_amt_f = transaction_amt.to_f
			#amt totals for individual products (could make this an object)
			product = sf_array[i][@sf_product_field]
			case product
				when "", nil
					#@sf_error_list += [sf_array[i][@sf_account_field]]
				else
					if product_amt_hash.has_key?(product)  
						product_amt_hash[product] += transaction_amt_f 
					else
						product_amt_hash[product] = transaction_amt_f 				
					end
			end
			# end of totaling amounts for individual products
			
			
		end
		
		case transaction_id
			when "", nil
				@sf_error_list += [sf_array[i][@sf_account_field]]
			when "N/A trial"
				#puts "TRIAL"
			when "N/A Comp"
			else
				if sf_hash.has_key?(transaction_id)  # Must sum up the individual line items in the transaction to match PayPal which has only one total per transaction
					sf_hash[transaction_id] += transaction_amt_f
					@salesforce_total += transaction_amt_f
				else
					sf_hash[transaction_id] = transaction_amt_f
					@salesforce_total += transaction_amt_f
				
				end
		end
		
		
		
		
	end
return sf_hash, product_amt_hash
end


def make_sf_product_count(sf_array)
	product_count_hash = {}

	for i in (@sf_start_line..(@sf_length-6))
		product = sf_array[i][@sf_product_field]
		
		case product
			when "", nil
				#@sf_error_list += [sf_array[i][@sf_account_field]]
			else
				if product_count_hash.has_key?(product)  
					product_count_hash[product] += 1
				else
					product_count_hash[product] = 1				
				end
		end
	end
return product_count_hash
end


begin

scrub_pp_csv(pp_file_name)
pp_array = csv_to_array(pp_file_name)
sf_array = csv_to_array(sf_file_name)

pp_length = pp_array.length()
@sf_length = sf_array.length()


pp_hash = make_pp_hash(pp_array, pp_start_line, pp_length, pp_transid_field, pp_amt_field)
sf_hash, sf_prod_amts = make_sf_hash(sf_array)
sf_product_count = make_sf_product_count(sf_array)

#puts pp_hash
#puts "xxxxxxxxxxxxxxxxxxxx"
#puts sf_hash


#################
#Find items in pp not in sf
##################
pp_hash.each do |transaction, amount|
	
	if sf_hash.has_key?(transaction)
		#puts "Match"
	else
		in_pp_not_sf[transaction] = amount
	
	end
	
end
#puts "IN PP NOT IN SF"
#puts in_pp_not_sf
###############
#Find items in sf not in pp
###############
#in_sf_not_pp = {}


sf_hash.each do |transaction, amount|
	
	if pp_hash.has_key?(transaction)
		#puts "Match"
	else
		in_sf_not_pp[transaction] = amount
	
	end
	
end

#puts "IN SF NOT IN PP"
#puts in_sf_not_pp
########################
#Find items with different $ amounts
#########################
pp_hash.each do |transaction, amount|
	
	if sf_hash.has_key?(transaction)  and not amount == sf_hash[transaction]
	     diff_amt_list[transaction] = (amount) - sf_hash[transaction]

	end
	
end

##############
# COUNT YEARLIES.Should really confirm that the product name is correct for that transaction. there is at least one hrm yearly maybe
#############
sf_hash.each do  |transaction, amount|
	case amount
		when @hi_yearly_amt
			@hi_yearly_count += 1
		
		when @hrm_yearly_amt
			@hrm_yearly_count += 1
		
	end

end

#######
# Difference total between two systems fomatted with 2 decimal places
######
sf_pp_difference = '%.2f' % (@salesforce_total-@paypal_total)


#puts
#puts "Transactions with different amounts"
#puts diff_amt_list

# make a routine that outputs a CSV from an array
###############################################
CSV.open(output_file_name, "wb") do |csv|
	csv << ["RECON OUTPUT"]
	csv << [Date.today]
	csv << []
	csv << ["Salesforce vs. PayPal Totals (positive transactions only)"]
	csv << ["System","Amount"]
	csv << ["Saleforce",@salesforce_total]
	csv << ["Paypal", @paypal_total]
	csv << ["-----------------------------------"]
	csv << ["Difference",sf_pp_difference]
	csv << []
	csv << ["Transaction in PayPal not in Salesforce"]
	csv << ["Transaction","Amount"]
	in_pp_not_sf.each do |transaction, amount|
		csv << [transaction, amount]
	end
	csv << []
	csv << ["Transaction in Salesforce not in PayPal"]
	csv << ["Transaction","Amount"]
	in_sf_not_pp.each do |transaction, amount|
		csv << [transaction, amount]
	end
	csv << []
	csv << ["Transactions with Different Amounts. PayPal - SalesForce"]
	csv << ["Transaction","Amount of Difference"]
	diff_amt_list.each do |transaction, amount|
		csv << [transaction, amount]
	end
	csv << []
	csv << ["SalesForce Error List. Items with no Transaction ID or Amount"]
	csv << ["Account Name"]
	@sf_error_list.each do |account_name|
		csv << [account_name]
	end
	csv << []
	
	csv << ["SalesForce DETAILED Product Dollar Amt Totals"]
	csv << ["Product","Count","Amount"]
	count_total=0 # this could be a good place to test injection or reduce
	amt_total=0.0
	sf_prod_amts.each do |product, amount|
		csv << [product,sf_product_count[product],amount]
		count_total += sf_product_count[product]
		amt_total += amount
	end
	csv << ["--------------------------------------------------"]
	csv << ["Total",count_total,amt_total]
	csv << []
	
	
	csv << ["SalesForce SUMMARY Product Dollar Amt Totals"]
	csv << ["Product","Count","Amount"]
	count_total=0 # this could be a good place to test injection or reduce
	amt_total=0.0
	hrm_count = 0
	hrm_amount = 0
	hi_amount = 0 
	hi_count = 0
	sf_prod_amts.each do |product, amount|
		case product
			when "Hedgeye Risk Manager", "Macro (22)" , "Macro (40)"
				hrm_count += sf_product_count[product]
				hrm_amount += amount
			when "Hedgeye Investor" , "HI2"
				hi_count += sf_product_count[product]
				hi_amount += amount
			else
				csv << [product,sf_product_count[product],amount]
		end
		
		count_total += sf_product_count[product]
		amt_total += amount
	end
	csv << ["Hedgeye Investor",hi_count,hi_amount]
	csv << ["Hedgeye Risk Manager",hrm_count,hrm_amount]
	csv << ["--------------------------------------------------"]
	csv << ["Total",count_total,amt_total]
	csv << []
	csv << ["Yearly Product Counts"]
	csv << ["Product","Amount","Count"]
	csv << ["Hedgeye Investor",@hi_yearly_amt,@hi_yearly_count]
	csv << ["Hedgeye Risk Manager",@hrm_yearly_amt,@hrm_yearly_count]
	
	
	
	
	
end

#puts @salesforce_total
#puts @paypal_total
#puts sf_product_count
#puts sf_prod_amts
puts "Reconciliation Complete"
puts "Press ENTER to finish"
STDIN.gets()


end

# annuals: HI $799, HRM $2499



########
# STILL NEED TO MAKE DOLLAR SUMMARY
########



#puts
#puts "SALES FORCE ERRORS"
#puts @sf_error_list







#puts pp_hash["4NS74816AF382715E"]

#pp_harray = pp_hash.to_a
#sf_harray = sf_hash.to_a

#diffpp = pp_harray - sf_harray

#puts diffpp

#difsf = sf_harray - pp_harray
#puts "xxxxxxxxxxxxxxxx"
#puts difsf


#pp_not_in_sf = pp_hash.to_a -  sf_hash.to_a
#NOW either loop through each hash looking up in the other
# OR flatten the hashes into arrays and then use array operations to compare array-array. to_a ?    OR h.flat_map { |k, vs| [k].product(vs) }


#puts pp_not_in_sf	



# IO.write("pp_recon.csv", '"XXX', 0)
#if pp_hash.has_key?(transaction_id)

# CSV.read(filename, :quote_char => "|")

# can also try the following x = 0 if x.nil?..................x ||=0
# array length FOO.length()
