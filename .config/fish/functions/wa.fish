function wa --description 'Wolfram Alpha query command'
    set -f APPID "$WOLFRAMALPHA_APIKEY" # Get one at https://products.wolframalpha.com/api/
    echo $argv | string escape --style=url | read question_string
    set -f url "https://api.wolframalpha.com/v1/result?appid="$APPID"&i="$question_string
    curl -s $url
end
