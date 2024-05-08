<#
Written By Derrick Baxter debaxter@microsoft.com 
5/8/24
Bash Script to get a token, checks if anything other than 200 is returned
checks if token retrieval or secret get is 200 OK, 429 throttled is hit (you can add backoff scripting here or retries +10 seconds or more) or any errors

#>

token=$(curl --write-out %{http_code} -f -v -D headers.txt -s 'http://169.254.169.254/metadata/identity/oauth2/token1?api-version=2018-02-01&resource=https://vault.azure.net' -H Metadata:true | awk -F"[{,\":}]" '{print $6}')


httpStatus=$(head -1 headers.txt | awk '{print $2}')
if [ "$httpStatus" -eq "200" ]; then
    echo "Token Retrieval worked - HTTP STATUS $httpStatus"
    pwd=$(curl --write-out %{http_code} -f -D headers2.txt -s "https://spnkeyvault1.vault.azure.net/secrets/spntest1?api-version=2016-10-01" -H "Authorization: Bearer ${token}" | jq -r ".value")
    httpGetSecret=$(head -1 headers2.txt | awk '{print $2}')
    if [ "$httpGetSecret" -eq "200" ]; then
      echo "Secret Lookup worked - HTTP STATUS $httpGetSecret secret $pwd" 
    else
          echo "Secret Lookup Failed - HTTP STATUS $httpGetSecret"
    fi
elif [ "$httpStatus" -eq "429" ]; then
    echo "Throttled - HTTP STATUS $httpStatus"
else
    echo "Other Failure - HTTP STATUS $httpStatus"
fi