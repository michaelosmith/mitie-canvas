#!/usr/bin/ruby
require 'open-uri'

download = open('https://instructure-uploads-apse2.s3-ap-southeast-2.amazonaws.com/account_24310000000000001/attachments/761/ICT%20-%20AV%20Support%20Technician%20Oct%202015.pdf?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIZAVS3WMRR54DT4Q%2F20170619%2Fap-southeast-2%2Fs3%2Faws4_request&X-Amz-Date=20170619T025819Z&X-Amz-Expires=900&X-Amz-SignedHeaders=host&X-Amz-Signature=15a90ac8b43d881939b23b7787dd6866ac8c837820efbc93be4d9279e7c0b3f9')

IO.copy_stream(download, "/Users/michaels/test.pdf")
