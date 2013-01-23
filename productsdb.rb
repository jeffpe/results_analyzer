# Automated products dashboard
# Product report csv to be named "productsreport.csv"
# Product report csv assumed to contain 
# 0.Opportunity Id	1.Opportunity: Opportunity Name	2.Created Date	3.Opportunity: Amount	4.Enabled	5.Product: Product Name	6.Hedgeye Access Status	7.Opportunity: Mass Market Status	8. Contact Full Name	9.Start Date	10.End Date	11.Opportunity: Start Date	12.Opportunity: End Date	13.Contact Email	14.Account Name ............Fields to be added 15 PromoorTrial 16.PromoCode	18. Present Last week 19. Last week amt 20. New Possible 21. New Definately 22. Lead Source 
# dont' forget the array starts at 0 not 1!!! 


# load in the csv library or whatever they call it in ruby
require "csv"
require "date"

# set the names of the products for tallying up the products in the CSV. should put into an array and then Could try some hashes?
hi_name = "Hedgeye Investor"
hrm_name = "Hedgeye Risk Manager"
hi2_name = "HI2"
macro22_name = "Macro (22)"
macro40_name = "Macro (40)"
mnl_name = "morning_newsletter_1"
combo3_name = "morning_stock_alerts_weekly_ideas_1"
rta_name = "Real-Time Alerts"
retailpro_name = "Retail PRO"
whi_name = "weekly_ideas_1"
internal_name = "internal"
product_list =["Hedgeye Investor", "Hedgeye Risk Manager", "HI2" , "Macro (22)" , "Macro (40)", "morning_newsletter_1", "morning_stock_alerts_weekly_ideas_1", "Real-Time Alerts","Retail PRO", "weekly_ideas_1",   "internal"]
# set the arrays of includes in email address that make the product line item internal or invalid; set the dollar amount to indicate a trial
# Internal test email addresses usually contain: "hedgeye.com", "example.com", "scottnelson", "mrjames", "spamcatch"
# Some guy has been given a free subscription for a contest for 1 year through 3/31/2013 "fred-strammer@comcast.net" but he is classified as a paying user
emailbadtext = ["hedgeye.com", "example.com", "scottnelson", "mrjames", "spamcatch", "fred-strammer@comcast.net","example2.com","tvannoy"]
maxtriallength = 18 # the maximum length in days of a trial. This also includes the grace period for billing

# set the column of the fields you want. 
productcol = 5 # the product field
emailcol = 13 # the email field
amtcol = 3 # the amount field
accstartcol = 9 #access start date field
accendcol = 10 # access end date field
prorticol = 15 # Promo or trial column
opidcolumn = 0 # op id colulmn
newpossiblecol = 20 # column in opportunity that tells possibly  new. Must run other tests to tell for sure
leadsourcecol=3 # column for the lead source in opportunitites

# set counts to zero.now that these are determined, redo as a hash
# can also try the following x = 0 if x.nil?..................x ||=0
hi_count = 0
hi_leadsource = {}
hrm_count = 0
hrn_leadsource = {}
hi2_count = 0
macro22_count = 0
macro40_count = 0
mnl_count = 0
combo3_count = 0
rta_count = 0
retailpro_count = 0
whi_count = 0
# internal count
internal_count = 0
# promo and trial counts
hrmpromo_count = 0
hrmtrial_count = 0
retailprotrial_count = 0
retailpropromo_count = 0
mnlpromo_count = 0
mnltrial_count = 0
rtapromo_count = 0
rtatrial_count = 0
whipromo_count = 0
whitrial_count = 0
trials = 0
promos = 0
newclients= 0
newprodcounter = {} # hash to count quantity new for each product
convertcount = 0
convertprodcounter = []
changedclients = 0
resubscribedclients = 0
leadsource_count = {}
product_leadsource = {}
product_ls_counter = {}

# Load this weeks product report the whole csv into an array. We got the memory. Why not?
products = CSV.read("products_this_week.csv")
productsfilelength = products.length() # do you need the parenthesis. NEED TO CHECK FOR NIL IN the csv as the last couple lines are a copyright notice
# puts products[0]
#puts productsfilelength

# Load last weeks product report 
previous_products = CSV.read("products_last_week.csv")
previous_productsfilelength = previous_products.length() # do you need the parenthesis. NEED TO CHECK FOR NIL IN the csv as the last couple lines are a copyright notice
#puts previous_products[0]
#puts previous_productsfilelength

# Create hashes for Last Weeks products. Amount and account length
previous_idhash = {'test' => "hello"}
previous_acclengthhash = {}

for i in (1..(previous_productsfilelength-8))  # should really test for the first blank line not use the -8. Note that it would have to check for a complete blank line as there are some lines with blank op ids in the first column
# last week amount
	previous_id_field = previous_products[i][0]
	pppamt = previous_products[i][3]
	previous_idhash[previous_id_field] = pppamt  # the prvious weeks amount. Note the op id here is the long version
	
# last week account length
	lw_acc_start_field = previous_products[i][accstartcol]
	lw_acc_end_field = previous_products[i][accendcol]

	lw_acct_length = Date.strptime(lw_acc_end_field, "%m/%d/%Y") - Date.strptime(lw_acc_start_field, "%m/%d/%Y")
	
	previous_acclengthhash[previous_id_field] = lw_acct_length
	
	# STDIN.gets()
	# puts "#{previous_id_field}: #{previous_idhash[previous_id_field]}"
end



#  READ IN THE OPPORTUNITY FILE
# 0.Opportunity ID	1.Opportunity Name	2.Opportunity Record Type	3.Lead Source	4.Type	5.Mass Market Status	6.Created Date	7.Start Date	8.End Date	9.Amount	Stage	10.Account Name

ops = CSV.read("opportunities_this_week.csv")
opsfilelength = ops.length() # do you need the parenthesis. NEED TO CHECK FOR NIL IN the csv as the last couple lines are a copyright notice
#puts ops[0]
#puts opsfilelength


# Create a hash for the ops id field to the opportunity type field which tells if its possibly (its not accurate) new, changed or resubscribed. Also create a hash for opportunity id to promo code when it is ready
all_ops_new = {'test' => "hello"}
all_ops_promo = {'test' => "hello"}
for i in (1..(opsfilelength-7))
	opsidfield = ops[i][0]
	newfield = ops[i][4] 
	promocodefield = ops[i][3]
	#puts "#{opsidfield}   #{newfield}   #{promocodefield}"
	
	# Create some hashes
	all_ops_new[opsidfield] = newfield
	all_ops_promo[opsidfield] = promocodefield #will have to create an array or hash  in the products file loop to count each kind of these. Or use the hash to set an array of the promos
	
end








# THE MASTER LOOP THROUGH EACH LINE IN THE PRODUCTS REPORT TO COUNT EVERYTHING

for i in (1..productsfilelength-8) # could also use an each with a  do with a block. try that next. also check on what the first line is the file is. Try with just 2 dots but adjust the products file length
	productfield = products[i][productcol] # this should be moved down after the valid check change
	emailfield = products[i][emailcol]
	amtfield = products[i][amtcol] # think about converting this to either an integer or floating point number rather then a string. That way it will catch both the 0.00 from sales force and the 0 from an excel generated csv
	fullopid = products[i][opidcolumn] #there are 3 extra character in this compared to my last opportunity report. The last one did not do this
	if fullopid !=nil; op_id_field = fullopid.chop.chop.chop; end# remove these 3 characters
	acc_start_field = products[i][accstartcol]
	acc_end_field = products[i][accendcol]
	
	#lw_acc_start_field = previous_products[i][accstartcol]
	#lw_acc_end_field = previous_products[i][accendcol]
	
	
	leadsource = all_ops_promo[op_id_field]
	# puts "amt field: #{amtfield}"
	internaluserflag = false
	promoflag = false
	trialflag = false
	convertflag = false
	# STDIN.gets()
	# puts productfield 
	# puts i
	# If loops to check for each product and increment the product counters. This should be changed to a for each loop using some kind of array of product names. also try using the percent sign to form the variable names
	# Add test if internal or some other banned name or email: example.com hedgeye.com mrjames scott smith
	# Add test for 0 dollar amount for promos and trials
	# Add test for promo period to tell if promo or trial
	# add combiner for HRM and HI. Here or after this process
	# there probably is a faster way to do this using and each loop on an array
	
	# CHECK FOR INTERNAL USER
	emailbadtext.each do |bademail|
		if emailfield == nil  #not sure if there are implications of doing this. probably should think more about this and the conditional loops below
			emailfield = "blank"
		end 
		
		if emailfield.include?(bademail)
			internaluserflag = true
			#puts "Internal Found" 
			#puts emailfield 
			#STDIN.gets()
		end
	end
	
	# if invalid change the product to internal.
	if internaluserflag == true
		products[i][productcol] = "internal"
		productfield = "internal" # if the productfield definition is moved down, this is no longer needed. must change in promo check as well
	end
	
	
	# CHECK IF A PROMO OR TRIAL. ATTEMPT TO SHOW THE DIFFERENCE. this will change is a promo code field is introduced
	
	
	#if emailfield.include?("barrycassese")
	#	puts "#{emailfield} #{amtfield}"
	#	STDIN.gets()
	#end
	
	
	
	
	if amtfield == "0.00" and productfield != "internal"   # SOMETIMES THE AMT is 0 and SOMETIME 0.00
		
		date_diff = Date.strptime(acc_end_field, "%m/%d/%Y") - Date.strptime(acc_start_field, "%m/%d/%Y")
		if date_diff > maxtriallength
			products[i][prorticol] = "promo"
			promos = promos + 1
			promoflag = true
			
		else
			products[i][prorticol] = "trial"
			trials = trials +1
			trialflag = true
			#puts "TRIAL FOUND #{emailfield} #{productfield} #{date_diff}"
			#puts Date.strptime(acc_end_field, "%m/%d/%Y")
			#puts Date.strptime(acc_start_field, "%m/%d/%Y")
			#STDIN.gets()
		end
	end
	
	
	# puts "Is it new before loop #{products[i][21]}"
	# puts "new count: #{newclients}"
	# STDIN.gets
	
	
	# CHECK FOR NEW ONES
	# Test this method---Try just This week array of ops - last week array of ops  for potentiial news then run tests
	if productfield != "internal" and promoflag == false and trialflag == false      # Not internal, trial or promo
		previousweekamt = previous_idhash[fullopid].to_s # think about converting this to either andinteger or floating point number rather then a string. That way it will catch both the 0.00 from sales force and the 0 from an excel generated csv
		# puts products[i][0]
		# puts "Email: #{emailfield} Current amt: #{amtfield}  Previous: #{previousweekamt}   All Ops new: #{all_ops_new[op_id_field]}"
		#if products[i][0] == "006C000000gohzIIAQ"
		#	
		#	previousweekamt.each_byte do |c|
		#		puts c
		#	end
		#	STDIN.gets()
		#end
		
		
		if all_ops_new[op_id_field]  == "New" and previousweekamt.empty?  #previous_idhash[fullopid] == nil  and  all_ops_new[op_id_field]  == "New" # check if present in previous week (indicateded by nil in last week amt) and op type is new
				#puts "ITS NEW #{productfield}"
				#puts products[i][emailcol]
				#STDIN.gets()
			products[i][21] = "New" # mark current record as new definately
		elsif previousweekamt == "0.00" and all_ops_new[op_id_field]  == "New" # and all_ops_new[op_id_field]  == "New"   
		# last week amt is 0. I thought you also needed to check if the op type field was new, but if a product amt was 0 last week and then got to >0 this week (or possibly blank) then it should be considered new. 
		# Sometime the system says they are resubscribe if they were an old lapsed subscriber who then did a trial or promo
			products[i][21] = "New" # mark current record as new definately
			convertflag = true
			
				#puts "ITS NEW #{productfield}"
				#puts products[i][emailcol]
				#STDIN.gets()
			
		end
	end
	
	
	# Count the products. This could be a nice hash now that it works
	if promoflag == false and trialflag == false
		if productfield == hi_name; hi_count += 1; end
		if productfield == hrm_name; hrm_count += 1; end
		if productfield == hi2_name; hi2_count += 1; end
		if productfield == macro22_name; macro22_count += 1; end
		if productfield == macro40_name; macro40_count += 1; end
		if productfield == mnl_name; mnl_count += 1; end
		if productfield == combo3_name; combo3_count += 1; end
		if productfield == rta_name; rta_count += 1 ; end
		if productfield == retailpro_name; retailpro_count += 1; end
		if productfield == whi_name; whi_count += 1; end
		if productfield == internal_name; internal_count += 1; end
	elsif promoflag == true and trialflag == false
		
		if productfield == hrm_name; hrmpromo_count += 1; end
		if productfield == mnl_name; mnlpromo_count += 1; end
		if productfield == rta_name; rtapromo_count += 1 ; end
		if productfield == retailpro_name; retailpropromo_count += 1; end
		if productfield == whi_name; whipromo_count += 1; end
		
		

			
	elsif promoflag == false and trialflag == true
		
		if productfield == hrm_name; hrmtrial_count += 1; end
		if productfield == mnl_name; mnltrial_count += 1; end
		if productfield == rta_name; rtatrial_count += 1 ; end
		if productfield == retailpro_name; retailprotrial_count += 1; end
		if productfield == whi_name; whitrial_count += 1; end
		
	elsif promoflag == true and trialflag == true
		puts "PROMO TRIAL FLAG ERROR"
	end
	
	
	# COUNT THE LEAD SOURCES
	if leadsource != nil and productfield != "internal" and (promoflag or trialflag) == true
		if not leadsource.empty?
			#puts product_ls_counter
			leadsource_count[leadsource] = 0 if leadsource_count[leadsource].nil?
			leadsource_count[leadsource] +=1
			product_leadsource[productfield] = 0 if product_leadsource[productfield].nil?
			product_leadsource[productfield] += 1
			#puts leadsource_count
			#puts product_leadsource
			
			unless defined? (product_ls_counter[leadsource][productfield])
				#puts "*******************************************************"
				#puts "STOP  FULL promo code its nil #{leadsource}"
				product_ls_counter[leadsource] = {productfield=>0}
			else
				if product_ls_counter[leadsource][productfield].nil?
					product_ls_counter[leadsource][productfield]=0
				end
			end
					
			product_ls_counter[leadsource][productfield] += 1
			#puts product_ls_counter
	
		end
	end
	
	
	
	# COUNT THE NEW. CHECK IF DEFINATELY NEW IS SET. (CAN ALSO ADD CHANGED AND RESUB LATER)
	if products[i][21] == "New"
		newclients += 1
		if newprodcounter[productfield].nil?
			newprodcounter[productfield] = 1
		else
			newprodcounter[productfield] += 1
		end
					
	
	#print products[i][13],   all_ops_new[op_id_field] 
	#puts
	end
	
	# COUNT THE CONVERTS
	if convertflag == true 
	# increment convert counter
		convertcount += 1
		convertprodcounter[(convertcount-1)]=[productfield, leadsource, (previous_acclengthhash[fullopid].to_i)]

		
		
		
	end
	
	

	
	
end


# puts "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# puts convertprodcounter
# STDIN.gets()


 # for goodness sake put this into somekind of array or hash of results and then output that to CSV, sql or screen
##############################################################################################################
# Output to a csv
	totalprods = hi_count+hrm_count+hi2_count+macro22_count+macro40_count+mnl_count+combo3_count+rta_count+retailpro_count+whi_count
CSV.open("reportoutput.csv", "wb") do |csv|
	csv << ["PAYING PRODUCT COUNTS"]
	csv << [hi_name, hi_count]
	csv << [hrm_name, hrm_count]
	csv << [hi2_name, hi2_count]
	csv << [macro22_name, macro22_count]
	csv << [macro40_name, macro40_count]
	csv << [mnl_name, mnl_count]
	csv << [combo3_name, combo3_count]
	csv << [rta_name, rta_count]
	csv << [retailpro_name, retailpro_count]
	csv << [whi_name, whi_count]
	csv << ["TOTAL PAYING", totalprods]
	csv << []
	csv << ["TRIAL PRODUCT COUNTS"]
	csv << [hrm_name, hrmtrial_count]
	csv << [retailpro_name, retailprotrial_count]
	csv << [mnl_name, mnltrial_count]
	csv << [rta_name, rtatrial_count]
	csv << [whi_name, whitrial_count]
	csv << ["TOTAL TRIALS", trials]
	csv << []
	csv << ["PROMO PRODUCT COUNTS"]
	csv << [hrm_name, hrmpromo_count]
	csv << [retailpro_name, retailpropromo_count]
	csv << [mnl_name, mnlpromo_count]
	csv << [rta_name, rtapromo_count]
	csv << [whi_name, whipromo_count]
	csv << ["TOTAL PROMOS", promos]
	csv << []
	csv << ["LEAD SOURCE SUMMARY"]
	leadsource_count.each do |lsource, lproductcount|
			csv << [lsource, lproductcount] 
	end
	csv << []
	csv << ["LEAD SOURCE BREAKOUT"]
	product_ls_counter.each do |lsource, lproductcount|
		csv << [lsource.upcase]
		lproductcount.keys.each do |subkey|   # .each_pair { |k, v| puts "Key: #{k}, Value: #{v}" }
			csv << [subkey, lproductcount[subkey]]
		end
	end
	
	
	csv << []
	csv << ["NEW PRODUCTS"]
	newprodcounter.each do |nproduct, nproductcount|
		csv << [nproduct, nproductcount]
	end
	csv << ["TOTAL NEW", newclients]
	csv << []
	csv << ["CONVERTED PRODUCTS"]
	csv << ["Product", "Lead Source", "Length of Promo"]
	convertprodcounter.each do |cproduct, cproductcount, clength|
		csv << [cproduct, cproductcount,clength]
	end
	csv << ["TOTAL CONVERTS", convertcount]
	csv << []
	csv << ["INTERNAL PRODUCT COUNTS"]
	csv << ["TOTAL INTERNAL or SPECIAL", internal_count]
	
	
	
	
	
end

# printf( "%-40s%5d\n","TOTAL RESUBSCRIBED: ", "#{resubscribedclients}")
# printf( "%-40s%5d\n","TOTAL CHANGED: ", "#{changedclients}")


##############################################################################################################



#def print_out
puts
printf("%-40s%5d\n", "#{hi_name}","#{hi_count}") # formatted in a column
printf( "%-40s%5d\n","#{hrm_name}","#{hrm_count}")
printf("%-40s%5d\n","#{hi2_name}","#{hi2_count}")
printf( "%-40s%5d\n","#{macro22_name}","#{macro22_count}")
printf( "%-40s%5d\n","#{macro40_name}","#{macro40_count}")
printf( "%-40s%5d\n","#{mnl_name}","#{mnl_count}")
printf( "%-40s%5d\n","#{combo3_name}","#{combo3_count}")
printf( "%-40s%5d\n","#{rta_name}","#{rta_count}")
printf( "%-40s%5d\n","#{retailpro_name}","#{retailpro_count}")
printf( "%-40s%5d\n","#{whi_name}","#{whi_count}")
totalprods = hi_count+hrm_count+hi2_count+macro22_count+macro40_count+mnl_count+combo3_count+rta_count+retailpro_count+whi_count
puts "-"*45
printf( "%-40s%5d\n","TOTAL PAYING: ", "#{totalprods}")


puts
# TRIALS
printf( "%-40s%5d\n","#{hrm_name} TRIAL","#{hrmtrial_count}")
printf( "%-40s%5d\n","#{retailpro_name} TRIAL","#{retailprotrial_count}")
printf( "%-40s%5d\n","#{mnl_name} TRIAL","#{mnltrial_count}")
printf( "%-40s%5d\n","#{rta_name} TRIAL","#{rtatrial_count}")
printf( "%-40s%5d\n","#{whi_name} TRIAL","#{whitrial_count}")
puts "-"*45
printf( "%-40s%5d\n","TOTAL TRIALS: ", "#{trials}")

#PROMOS
puts
printf( "%-40s%5d\n","#{hrm_name} PROMO","#{hrmpromo_count}")
printf( "%-40s%5d\n","#{retailpro_name} PROMO","#{retailpropromo_count}")
printf( "%-40s%5d\n","#{mnl_name} PROMO","#{mnlpromo_count}")
printf( "%-40s%5d\n","#{rta_name} PROMO","#{rtapromo_count}")
printf( "%-40s%5d\n","#{whi_name} PROMO","#{whipromo_count}")
puts "-"*45
printf( "%-40s%5d\n","TOTAL PROMOS: ", "#{promos}")

#NEW CHANGED RESUBSCRIBED
puts
newprodcounter.each do |nproduct, nproductcount|
	printf( "%-40s%5d\n", "#{nproduct}", "#{nproductcount}")
end
puts "-"*45
printf( "%-40s%5d\n","TOTAL NEW: ", "#{newclients}")

# CONVERTS
puts
#convertprodcounter.each do |cproduct, cproductcount|
	#printf( "%-40s%5d\n", "#{cproduct}", "#{cproductcount}")
#end
puts "-"*45
printf( "%-40s%5d\n","TOTAL CONVERTS: ", "#{convertcount}")

#INTERNALS
puts
printf( "%-40s%5d\n","TOTAL INTERNAL or COMP: ", "#{internal_count}")


# printf( "%-40s%5d\n","TOTAL RESUBSCRIBED: ", "#{resubscribedclients}")
# printf( "%-40s%5d\n","TOTAL CHANGED: ", "#{changedclients}")
#end

#print_out

puts
puts
puts "ALL FINISHED....PRESS RETURN TO EXIT"
STDIN.gets()
