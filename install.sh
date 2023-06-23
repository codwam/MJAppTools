dir=$(pwd)
path="${dir}/Release/re"
echo "Local file path: ${path}"
make && scp -P 2222 $path root@127.0.0.1:/usr/bin/
