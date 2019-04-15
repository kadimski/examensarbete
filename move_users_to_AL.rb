require 'httparty'
require 'json'

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

# canvas group name
$group_name = "2019-04-21 08:00 Test test Ellen FakeStudent"

##### Returns the group set id for a given group set #####

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

$al1_id = get_group_set_id("Active listener group 1")
$al2_id = get_group_set_id("Active listener group 2")
$al_id = get_group_set_id("Active listener group")

##### Returns the group id for a given group name in a group set #####

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

$al1_group_id = get_group_id($al1_id, $group_name)
$al2_group_id = get_group_id($al2_id, $group_name)
$al_group_id = get_group_id($al_id, $group_name)

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

###############################

$arr_of_user_ids_AL1 = get_users_in_group($al1_group_id)
$arr_of_user_ids_AL2 = get_users_in_group($al2_group_id)

$arr_of_user_ids = $arr_of_user_ids_AL1 + $arr_of_user_ids_AL2

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

###############################

move_users_to_group($al_group_id, $arr_of_user_ids)

#### Returns an array of user ids who have participated in the discussion, assuming only one discussion in a group ####

def get_discussing_users(group_id)
    @url = "http://#{$canvas_host}/api/v1/groups/#{group_id}/discussion_topics"
    puts "@url is #{@url}"

    @getResponse = HTTParty.get(@url, :headers => $header)
    puts(" GET to get discussing users in group has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")

    discussion_data = @getResponse.parsed_response
    discussion_id = nil

    discussion_data.each do |discussion_info|
        discussion_id = discussion_info["id"]
    end

    @url = "http://#{$canvas_host}/api/v1/groups/#{group_id}/discussion_topics/#{discussion_id}/entries"
    puts "@url is #{@url}"

    @getResponse = HTTParty.get(@url, :headers => $header)
    puts(" GET to list discussion entries in group has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")

    discussion_entries_data = @getResponse.parsed_response
    arr_of_discussing_user_ids = Array.new

    discussion_entries_data.each do |discussion_entries_info|
        arr_of_discussing_user_ids.push discussion_entries_info["user_id"]
    end

    return arr_of_discussing_user_ids
end

##########################################

arr_of_discussing_user_ids = get_discussing_users($al_group_id)

#### Grades students who have participated in the discussion ####

def grade_users(arr_of_discussing_user_ids)
    @url = "http://#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/assignments"
    puts "@url is #{@url}"

    @getResponse = HTTParty.get(@url, :headers => $header)
    puts(" GET to get assignments in course has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")

    assignments_data = @getResponse.parsed_response
    assignment_AL1_id = nil
    assignment_AL2_id = nil

    assignments_data.each do |assignments_info|
        if assignments_info["name"] == "AL1"
            assignment_AL1_id = assignments_info["id"]
        elsif assignments_info["name"] == "AL2"
            assignment_AL2_id = assignments_info["id"]
        end
    end

    arr_of_discussing_user_ids.each { |id|
        if $arr_of_user_ids_AL1.include?(id)
            @url = "http://#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/assignments/#{assignment_AL1_id}/submissions/#{id}"
            puts "@url is #{@url}"

            @payload={'submission[posted_grade]': "pass"}
            puts("@payload is #{@payload}")

            @putResponse = HTTParty.put(@url, :body => @payload.to_json, :headers => $header )
            puts(" PUT to grade assignment for user has Response.code #{@postResponse.code} and postResponse is #{@postResponse}")
        elsif $arr_of_user_ids_AL2.include?(id)
            @url = "http://#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/assignments/#{assignment_AL1_id}/submissions/#{id}"
            puts "@url is #{@url}"

            @payload={'submission[posted_grade]': "pass"}
            puts("@payload is #{@payload}")

            @putResponse = HTTParty.put(@url, :body => @payload.to_json, :headers => $header )
            puts(" PUT to grade assignment for user has Response.code #{@postResponse.code} and postResponse is #{@postResponse}")
        else
            puts "Something went wrong"
        end
    }
end

##########################################

grade_users(arr_of_discussing_user_ids)