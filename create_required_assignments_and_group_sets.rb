require 'httparty'
require 'json'

config = JSON.parse(File.read('/home/maguire/utils/config.json'))
#puts "config: #{config}"

access_token = config['canvas']['access_token']
#puts "access_token: #{access_token}"

host = config['canvas']['host']
puts "host: #{host}"

# canvas course id
$canvas_course_id = config['canvas']['course_id']
puts "canvas_course_id: #{$canvas_course_id}"

# a global variable to help the hostname
$canvas_host=host

$header = {'Authorization': 'Bearer ' "#{access_token}", 'Content-Type': 'application/json', 'Accept': 'application/json'}
puts "$header: #{$header}"

def create_group_set(name, self_signup)
    @url = "http://#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/group_categories"
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

def create_assignment(name)
    @url = "http://#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/assignments"
    puts "@url is #{@url}"

    @payload={'assignment': { 
                                'name': name,
                                'points_possible': '0',
                                'grading_type': 'pass_fail',
                                'published': 'true',
                                'submission_types': [ "none" ]
                            }
    }

    @postResponse = HTTParty.post(@url, :body => @payload.to_json, :headers => $header )
    puts(" POST to create assignment has Response.code #{@postResponse.code} and postResponse is #{@postRepsone}")
end

create_group_set("Active listener group 1", true)
create_group_set("Active listener group 2", true)
create_group_set("Active listener group", false)

create_assignment("1: aktiv lyssnare / active listener")
create_assignment("2: aktiv lyssnare / active listener")