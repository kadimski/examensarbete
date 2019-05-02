require 'httparty'
require 'json'

config = JSON.parse(File.read('/home/maguire/utils/config.json'))
#puts "config: #{config}"

access_token = config['canvas']['access_token']
#puts "access_token: #{access_token}"

host = config['canvas']['host']
puts "host: #{host}"

# a global variable to help the hostname
$canvas_host=host

$header = {'Authorization': 'Bearer ' "#{access_token}", 'Content-Type': 'application/json', 'Accept': 'application/json'}
puts "$header: #{$header}"

# canvas course id
$canvas_course_id = 4

def create_group_set(name, self_signup)
    @url = "#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/group_categories"
    puts "@url is #{@url}"

    if self_signup == true
        @payload={'name': name, 
            'self_signup': 'enabled'}
        puts("@payload is #{@payload}")

        @postResponse = HTTParty.post(@url, :body => @payload.to_json, :headers => $header )
        puts(" POST to create group set has Response.code #{@postResponse.code} and postResponse is #{@postResponse}")  
    else   
        @payload={'name': name}
        puts("@payload is #{@payload}")

        @postResponse = HTTParty.post(@url, :body => @payload.to_json, :headers => $header )
        puts(" POST to create group set has Response.code #{@postResponse.code} and postResponse is #{@postResponse}")
    end
end 

create_group_set("AL", false)
create_group_set("AL1", true)
create_group_set("AL2", true)