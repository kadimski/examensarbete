require 'httparty'
require 'json'
require 'nitlink'

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

# link parser for paginated get requests
$link_parser = Nitlink::Parser.new

#### Creates group set with a given name and self signup option ####
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

########################################## 

#### Creates an assignment with a given name ####
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

##########################################

#### Checks if a given group set exists ####
def check_if_group_set_exists(group_set_name)
    group_set_arr = Array.new

    @url = "http://#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/group_categories"
    puts "@url is #{@url}"
    
    @getResponse = HTTParty.get(@url, :headers => $header)
    puts(" GET to get group sets has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")
    
    if $link_parser.parse(@getResponse).by_rel('next')
        group_set_arr.append(@getResponse.parsed_response)

        while $link_parser.parse(@getResponse).by_rel('next')
            @url = $link_parser.parse(@getResponse).by_rel('next').target
            puts "@url is #{@url}"

            @getResponse = HTTParty.get(@url, :headers => $header)
            puts(" GET to get group sets has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")
            
            group_set_arr.append(@getResponse.parsed_response)
        end

        group_set_arr.each { |group_set_data|
            group_set_data.each do |group_set_info|
                if group_set_info["name"] == group_set_name
                    return true  
                end
            end
        }

        return false
    else
        group_set_data = @getResponse.parsed_response
    
        group_set_data.each do |group_set_info|
            if group_set_info["name"] == group_set_name
                return true  
            end
        end
    
        return false
    end
end

##########################################

#### Checks if an assignment exists ####
def check_if_assignment_exists(name)
    @url = "http://#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/assignments"
    puts "@url is #{@url}"

    @getResponse = HTTParty.get(@url, :headers => $header)
    puts(" GET to get assignments in course has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")

    assignments_data = @getResponse.parsed_response

    assignments_data.each do |assignments_info|
        if assignments_info["name"] == name
            return true
        end
    end

    return false
end

##########################################

if check_if_group_set_exists("Active listener group 1")
    puts "Active listener group 1 exists"
else
    create_group_set("Active listener group 1", true)
end

if check_if_group_set_exists("Active listener group 2")
    puts "Active listener group 2 exists"
else
    create_group_set("Active listener group 2", true)
end

if check_if_group_set_exists("Active listener group")
    puts "Active listener group exists"
else
    create_group_set("Active listener group", false)
end

if check_if_assignment_exists("1: aktiv lyssnare / active listener")
    puts "1: aktiv lyssnare / active listener exists"
else
    create_assignment("1: aktiv lyssnare / active listener")
end

if check_if_assignment_exists("2: aktiv lyssnare / active listener")
    puts "2: aktiv lyssnare / active listener exists"
else
    create_assignment("2: aktiv lyssnare / active listener")
end