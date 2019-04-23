require 'httparty'
require 'json'
require 'date'

config = JSON.parse(File.read('config.json'))
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
$canvas_course_id = 5

# today's date
$todays_date = Date.today.to_s

#### Returns groups in a group set as a parsed response ####
def get_groups_in_group_set(group_set_id)
    @url = "http://#{$canvas_host}/api/v1/group_categories/#{group_set_id}/groups"
    puts "@url is #{@url}"
    
    @getResponse = HTTParty.get(@url, :headers => $header)
    puts(" GET to get groups in group set has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")
  
    group_set_data = @getResponse.parsed_response
  
    return group_set_data
end

##################################

#### Returns the group set id for a given group set ####
def get_group_set_id(group_set_name)
    @url = "http://#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/group_categories"
    puts "@url is #{@url}"
    
    @getResponse = HTTParty.get(@url, :headers => $header)
    puts(" GET to get group set id has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")
  
    group_set_data = @getResponse.parsed_response
    group_set_id = nil 
  
    group_set_data.each do |group_set_info|
        if group_set_info["name"] == group_set_name
            group_set_id = group_set_info["id"]  
        end
    end
  
    return group_set_id
end

##################################

#### Returns the group id for a given group name in a group set ####
def get_group_id(group_set_id, group_name)
    @url = "http://#{$canvas_host}/api/v1/group_categories/#{group_set_id}/groups"
    puts "@url is #{@url}"
  
    @getResponse = HTTParty.get(@url, :headers => $header)
    puts(" GET to get group id has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")
  
    group_data = @getResponse.parsed_response
    group_id = nil
  
    group_data.each do |group_data_info|
        if group_data_info["name"] == group_name
            group_id = group_data_info["id"]  
        end
    end
  
    return group_id
end

##################################

#### Returns an array of user ids from a given group ####
def get_users_in_group(group_id)
    @url = "http://#{$canvas_host}/api/v1/groups/#{group_id}/users"
    puts "@url is #{@url}"

    @getResponse = HTTParty.get(@url, :headers => $header)
    puts(" GET to get users in group has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")

    user_data = @getResponse.parsed_response
    arr_of_user_ids = Array.new

    user_data.each do |user_data_info|
        arr_of_user_ids.push user_data_info["id"]
    end 

    return arr_of_user_ids
end

##################################

#### Move an array of users to a given group ####
def move_users_to_group(group_id, arr_of_user_ids)
    arr_of_user_ids.each { |id|
      @url = "http://#{$canvas_host}/api/v1/groups/#{group_id}/memberships"
      puts "@url is #{@url}"
  
      @payload={'user_id': id}
      puts("@payload is #{@payload}")
  
      @postResponse = HTTParty.post(@url, :body => @payload.to_json, :headers => $header )
      puts(" POST to move users to group has Response.code #{@postResponse.code} and postResponse is #{@postResponse}")
    }
end

##################################

al1_id = get_group_set_id("Active listener group 1")
al2_id = get_group_set_id("Active listener group 2")
al_id = get_group_set_id("Active listener group")

groups = get_groups_in_group_set(al_id)

groups.each do |group_info|
    group_date = group_info["name"].split(" ").first
    if $todays_date == group_date && group_info["members_count"] <= 2
        al1_group_id = get_group_id(al1_id, group_info["name"])
        al2_group_id = get_group_id(al2_id, group_info["name"])
        al_group_id = get_group_id(al_id, group_info["name"])

        arr_of_user_ids_AL1 = get_users_in_group(al1_group_id)
        arr_of_user_ids_AL2 = get_users_in_group(al2_group_id)

        arr_of_user_ids = arr_of_user_ids_AL1 + arr_of_user_ids_AL2

        move_users_to_group(al_group_id, arr_of_user_ids)
    end
end