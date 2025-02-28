#this is just a template, there must be some logic that identifies files to tar for specific model years
find outdata/ -name "*5?????.??*.codes" | sort | tar -czf codes_5001-5999.tgz -T -
find outdata/ -name "*5?????.??*.codes" -exec rm {} \;
