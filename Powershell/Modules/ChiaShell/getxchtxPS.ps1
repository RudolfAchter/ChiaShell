# -----------------------------------------------------------------------------------
# XCH Transaction Exporter : getxchtxPS - Windows Powershell Edition
# Generate a list of transactions for Chia (XCH) into a CSV file.
#
# Disclaimer: For educational purposes only. This is not tax, nor financial advice. 
# -----------------------------------------------------------------------------------

Function Convert-FromUnixDate ($UnixDate) {
    [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($UnixDate))
 }
 
 Function Mojo2XCH ($amount) {
    [decimal]$amount/1000000000000
 }
 
 Function Usage() {
     Write-Output "Usage: .\getxchtxPS [OPTIONS]"
     Write-Output ""
     Write-Output "Options:"
     Write-Output "  -f INTEGER       Set the fingerprint to specify which wallet to use  [required]"
     Write-Output "  -i INTEGER       Id of the wallet to use                             [default: 1; required]"
     Write-Output "  -j FILENAME      Output to ASCII file instead of screen              [default: none]"
     Write-Output "  -o INTEGER       Skip transactions from the beginning of the list    [default: 0; required]"
     Write-Output "  -l INTEGER       Max number of transactions to return                [default: 4294967295]"
     Write-Output "  -y YEAR          Filter transactions to given 4-digit year (or all)  [default: all]"
     Write-Output "  -min XCH         Filter to transactions greater than XCH given       [default: 0]"
     Write-Output "  -max XCH         Filter to transactions less than XCH given          [default: 999999]"
     Write-Output "  -t INTEGER       Filter by transaction type                          [default: -1]"
     Write-Output "                          -1 All transaction types"
     Write-Output "                           0 INCOMING_TX"
     Write-Output "                           1 OUTGOING_TX"
     Write-Output "                           2 COINBASE_REWARD"
     Write-Output "                           3 FEE_REWARD"
     Write-Output "                           4 INCOMING_TRADE"
     Write-Output "                           5 OUTGOING_TRADE"
     Write-Output "  -v               Verbose output"
     Write-Output "  -h, --help       Show this message and exit"
     Write-Output ""
     Write-Output "Do not use -o or -l with any of the filter options (year, min, max, type)."
     Write-Output ""
     Write-Output "Example:"
     Write-Output "     .\getxchtxPS -y 2021 -v"
     Write-Output ""
     Write-Output "Example for saving to file:"
     Write-Output "     .\getxchtxPS -y 2021 > tx_list.csv"
 }
 
 # set our defaults
 $fingerprint = ""
 $year = "all"
 $wallet_id = 1
 $offset = 0
 $limit = 4294967295
 $min = 0
 $max = 999999
 $type = -1
 $verbose = "false"
 $outfile = ""
 
 # get the command line arguments, these will override the defaults
 for ( $i = 0; $i -lt $args.count; $i++ ) {
     switch ($($args[$i]))
     {
         "-f" {$fingerprint = $args[$i+1]; Break}
         "-y" {$year = $args[$i+1]; Break}
         "-i" {$wallet_id = $args[$i+1]; Break}
         "-j" {$outfile = $args[$i+1]; Break}
         "-o" {$offset = $args[$i+1]; Break}
         "-l" {$limit = $args[$i+1]; Break}
         "-min" {$min = $args[$i+1]; Break}
         "-max" {$max = $args[$i+1]; Break}
         "-t" {$type = $args[$i+1]; Break}
         "-v" {$verbose = "true"; Break}
         "-h" {Usage; Exit; Break}
     }
 } 
 
 if ($fingerprint -eq "") { Write-Output "Error: fingerprint missing."; Usage; Exit }
 
 # path to powershell script
 $scripthome=pwd
 
 # path to chia executable
 $appfolder=Get-ChildItem $ENV:LOCALAPPDATA\chia-blockchain -Directory -Filter "app*" | Sort-Object -Property Name -Descending | Select-Object -First 1
 $path="$ENV:LOCALAPPDATA\chia-blockchain\" + $appfolder.Name + "\resources\app.asar.unpacked\daemon"
 
 # change working directory into the chia executable path
 cd $path
 
 # command options for fingerprint, wallet_it, offset, limit, and verbose are sent to the Chia get_transaction command
 # chia command must include -v for verbose. the command option for verbose of this script is used below for the CSV file
 $json=chia wallet get_transactions -f $fingerprint -i $wallet_id -o $offset -l $limit -v --no-paginate
 
 # change the directory into the powershell script path
 cd $scripthome
 
 # we need to do a little massaging to the json return from the Chia RPC endpoint
 # to get Powershell Json tools to work properly with it. 
 # Hat Tip to @bearcat9425 for spotting some json validation I missed.
 # Fixing some capitalization, single/double quotes, missing commas, and wrapping it all in an array block to make Powershell happy.
 $json.replace('None',' "none"').replace("'","""").replace("False,","false,").replace("True,","true,") | Out-File $scripthome/alltxs.json
 
 # Since we are using StringBuilder, we need to cast the return as void
 # to keep StringBuilder from dumping a bunch of data to the screen.
 $fix = [System.Text.StringBuilder]::new()
 [void]$fix.Append("[")
 foreach($line in Get-Content alltxs.json) {
     if($line.Contains("wallet_id")){
         [void]$fix.AppendLine($line + ",")
     }else
     {
         [void]$fix.AppendLine($line)
     }
 }
 [void]$fix.Append("]")
 
 # initialize a CSV output file
 $csv = [System.Text.StringBuilder]::new()
 
 # pull in the transactions from the (corrected) json file
 $fix = $fix.ToString().Remove($fix.ToString().Length -4,1)
 $fix | Out-File $scripthome/alltxs_fixed.json -Encoding ASCII
 $transactions = ($fix | ConvertFrom-Json)
 
 # setup a header for both normal and verbose
 # write header to CSV file
 if ($verbose -eq "true") {
     [void]$csv.AppendLine("fingerprint,tx_name,tx_datetime,tx_type,tx_amount,current_price,tx_fee_amount,tx_created_at_time,tx_additions,tx_confirmed,tx_confirmed_at_height,tx_memos,tx_removals,tx_sent,tx_sent_to,tx_spend_bundle,tx_to_address,tx_to_puzzle_hash,tx_trade_id,tx_wallet_id")
 } else {
     [void]$csv.AppendLine("fingerprint,tx_name,tx_datetime,tx_type,tx_amount,current_price,tx_fee_amount")
 }
 
 # loop through transactions and process
 foreach ($transaction in $transactions)
 {
     # make sure we start with an empty string for each record
     $row = ""
 
     # pull out the fields from the transaction record
     $tx_name = $transaction.name
     $tx_created_at_time = $transaction.created_at_time
     $tx_type = $transaction.type
     
     # if the type isn't -1 for all, and doesn't match command option then skip to next record
     if($type -ge 0 -and $type -ne $tx_type) { Continue }
     
     # convert mojo to XCH
     $tx_amount = Mojo2XCH $transaction.amount
     
     # if the amount is less than the min then skip to the next record
     if ($tx_amount -lt $min) { Continue }
     
     # if the amount is more than the max then skip to the next record
     if ($tx_amount -gt $max) { Continue }
     
     $tx_additions = $transaction.additions
     $tx_confirmed = $transaction.confirmed
     $tx_confirmed_at_height = $transaction.confirmed_at_height
     
     # convert mojo to XCH
     $tx_fee_amount = Mojo2XCH $transaction.fee_amount
     
     $tx_memos = $transaction.memos
     $tx_removals = $transaction.removals
     $tx_sent = $transaction.sent
     $tx_sent_to = $transaction.sent_to
     $tx_spend_bundle = $transaction.spend_bundle
     $tx_to_address = $transaction.to_address
     $tx_to_puzzle_hash = $transaction.to_puzzle_hash
     $tx_trade_id = $transaction.trade_id
     $tx_wallet_id = $transaction.wallet_id
 
     # convert epoch to datetime
     $tx_datetime = Convert-FromUnixDate $tx_created_at_time
     if($tx_datetime.Year -ne $year -and $year -ne "all") { Continue }
 
     # set a good description for the transaction type
     switch ($tx_type)
     {
         0 {$tx_typedesc = "INCOMING_TX"; Break}
         1 {$tx_typedesc = "OUTGOING_TX"; Break}
         2 {$tx_typedesc = "COINBASE_REWARD"; Break}
         3 {$tx_typedesc = "FEE_REWARD"; Break}
         4 {$tx_typedesc = "INCOMING_TRADE"; Break}
         5 {$tx_typedesc = "OUTGOING_TRADE"; Break}
     }
 
     # build the additions array into a string for output
     $tx_addfields = ""
     foreach ($add in $tx_additions) {
         $tx_addfields = $tx_addfields + $add
     }
     
     # build the removals array into a string for output
     $tx_removefields = ""
     $newamount = 0
     foreach ($remove in $tx_removals) {
         $tx_removefields = $tx_removefields + $remove
         $newamount = $newamount + $remove.amount
     }
     
     # build the memo array into a string for output
     $tx_memofields = ""
     foreach ($memo in $tx_memos) {
         $tx_memofields = $tx_memofields + $memo
     }
 
     # build the sent_to array into a string for output
     $tx_senttofields = ""
     foreach ($sentto in $tx_sent_to) {
         $tx_senttofields = $tx_senttofields + $sentto
     }
 
     # use a place holder for the current price so there is a column in the CSV
     $tx_current_price = 0
 
     # need to evaluate if Transaction Type is OUTGOING_TX and if so sum up the Removal
     # amounts and use instead of just tx_amount.
     if ($tx_typedesc -eq "OUTGOING_TX") {
         
         # pull all fields from removals into an array that we loop through and add up
         # amounts to remove (these are the coins spent, change will come back in a
         # separate transaction.
         $tx_amount = Mojo2XCH $newamount
     }
 
     # these first few fields will be for the normal output
     $row = $fingerprint.ToString()
     $row = $row + "," + $tx_name
     $row = $row + "," + $tx_datetime
     $row = $row + "," + $tx_typedesc
     $row = $row + "," + $tx_amount
     $row = $row + "," + $tx_current_price
     $row = $row + "," + $tx_fee_amount
 
     # check to see if command option for verbose is selected
     if ($verbose -eq "true") {
         $row = $row + "," + $tx_created_at_time
         $row = $row + "," + $tx_addfields
         $row = $row + "," + $tx_confirmed
         $row = $row + "," + $tx_confirmed_at_height
         $row = $row + "," + $tx_memofields
         $row = $row + "," + $tx_removefields
         $row = $row + "," + $tx_sent
         $row = $row + "," + $tx_senttofields
         $row = $row + "," + $tx_spend_bundle
         $row = $row + "," + $tx_to_address
         $row = $row + "," + $tx_to_puzzle_hash
         $row = $row + "," + $tx_trade_id
         $row = $row + "," + $tx_wallet_id
     }
     [void]$csv.AppendLine($row)
 }
 
 # write the transaction out to the CSV file
 if ($outfile -ne "")
 {
     Set-Content $outfile $csv.ToString() -Encoding ASCII
 } else {
     Write-Output $csv.ToString()
 }
 
 cd $scripthome
 
 # Version History
 #
 # v0.1.0 - Initial Release:
 #            - Basic functionality. Will generate a list of transactions for Chia (XCH) and
 #                put into a CSV file. Pulls details for each transaction using Chia wallet commands.
 #            - Output was sent to the screen. Must use command line redirection to save to a file.
 #                .\getxchtxPS -f 3812331296 -i 1 >my_transactions.csv
 # 
 # v0.1.1 - Changes:
 #            - Better documentation. How to Get the Script, How to Open Powershell, How to get 
 #                your fingerprint, How to run the script, How to use Advanced Features or command 
 #                options, Examples of normal output and verbose output.
 #          New features:
 #            - Added Fee Amount into the normal output.
 #            - Added Fingerprint into both normal and verbose output.
 #            - Added Created At Time back into the Verbose output.
 # v0.2.0 - Changes:
 #            - Fixed issue where the script used amount for Outgoing Tx transactions instead of the
 #                Removals totaled amount. Thanks @Jacek-ghub for reporting this critical bug!
 #            - Script now determines the Username & Version automatically without requiring editing
 #                the script prior to using.
 #            - Correct variable name in Verbose Output for the Removal collection which caused the
 #                removals to be empty.
 #          New features:
 #            - Added Encoding ASCII to the JSON file that all transactions are stored in.
 #            - Added command option to set the desired filename for the ASCII output file. This will
 #                write directly to the file without requiring Redirection. No output will be displayed
 #                to the screen during processing.