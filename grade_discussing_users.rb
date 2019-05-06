require 'httparty'
require 'json'
require 'date'

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
$canvas_course_id = 5

# today's date
$todays_date = Date.today.to_s

#### Returns groups in a group set as a an array of parsed responses ####
def get_groups_in_group_set(group_set_id)
    group_set_data = Array.new

    @url = "http://#{$canvas_host}/api/v1/group_categories/#{group_set_id}/groups?per_page=1"
    puts "@url is #{@url}"
        
    @getResponse = HTTParty.get(@url, :headers => $header)
    puts(" GET to get groups in group set has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")
    group_set_data.append(@getResponse.parsed_response)

    while $link_parser.parse(@getResponse).by_rel('next')
        @url = $link_parser.parse(@getResponse).by_rel('next').target
        puts "@url is #{@url}"

        @getResponse = HTTParty.get(@url, :headers => $header)
        puts(" GET to get groups in group set has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")
            
        group_set_data.append(@getResponse.parsed_response)
    end
  
    return group_set_data
end

##########################################

#### Returns the group set id for a given group set ####
def get_group_set_id(group_set_name)
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
                if group_set_info["name"] == group_name
                    return group_set_id = group_set_info["id"]  
                end
            end
        }
    else
        group_set_data = @getResponse.parsed_response
        group_set_id = nil 
    
        group_set_data.each do |group_set_info|
            if group_set_info["name"] == group_set_name
                group_set_id = group_set_info["id"]  
            end
        end
    
        return group_set_id
    end
end

##########################################

#### Returns the group id for a given group name in a group set ####
def get_group_id(group_set_id, group_name)
    group_data_arr = Array.new

    @url = "http://#{$canvas_host}/api/v1/group_categories/#{group_set_id}/groups?per_page=1"
    puts "@url is #{@url}"
  
    @getResponse = HTTParty.get(@url, :headers => $header)
    puts(" GET to get groups in a group set has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")
    
    if $link_parser.parse(@getResponse).by_rel('next')
        group_data_arr.append(@getResponse.parsed_response)

        while $link_parser.parse(@getResponse).by_rel('next')
            @url = $link_parser.parse(@getResponse).by_rel('next').target
            puts "@url is #{@url}"

            @getResponse = HTTParty.get(@url, :headers => $header)
            puts(" GET to get groups in a group set has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")
            
            group_data_arr.append(@getResponse.parsed_response)
        end

        group_data_arr.each { |group_data|
            group_data.each do |group_data_info|
                if group_data_info["name"] == group_name
                    return group_id = group_data_info["id"]  
                end
            end
        }
    else
        group_data = @getResponse.parsed_response
        group_id = nil
    
        group_data.each do |group_data_info|
            if group_data_info["name"] == group_name
                group_id = group_data_info["id"]  
            end
        end

        return group_id
    end
end

##########################################

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

##########################################

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

#### Grades students who have participated in the discussion and fails those who have not ####
def grade_users(arr_of_discussing_user_ids, arr_of_user_ids_AL1, arr_of_user_ids_AL2)
    
    @url = "http://#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/assignments"
    puts "@url is #{@url}"

    @getResponse = HTTParty.get(@url, :headers => $header)
    puts(" GET to get assignments in course has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")

    assignments_data = @getResponse.parsed_response
    assignment_AL1_id = nil
    assignment_AL2_id = nil

    assignments_data.each do |assignments_info|
        if assignments_info["name"] == "1: aktiv lyssnare / active listener"
            assignment_AL1_id = assignments_info["id"]
        elsif assignments_info["name"] == "2: aktiv lyssnare / active listener"
            assignment_AL2_id = assignments_info["id"]
        end
    end

	arr_of_user_ids_AL1.each { |id|
		if arr_of_discussing_user_ids.include?(id)
			@url = "http://#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/assignments/#{assignment_AL1_id}/submissions/#{id}"
            puts "@url is #{@url}"

            @payload={'submission': {
                                        'posted_grade': 'pass'}
            }
            puts("@payload is #{@payload}")

            @putResponse = HTTParty.put(@url, :body => @payload.to_json, :headers => $header )
            puts(" PUT to grade assignment for user has Response.code #{@putResponse.code} and postResponse is #{@putResponse}")
		else
			@url = "http://#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/assignments/#{assignment_AL1_id}/submissions/#{id}"
            puts "@url is #{@url}"

            @payload={'submission': {
                                        'posted_grade': 'fail'}
            }
            puts("@payload is #{@payload}")

            @putResponse = HTTParty.put(@url, :body => @payload.to_json, :headers => $header )
            puts(" PUT to grade assignment for user has Response.code #{@putResponse.code} and postResponse is #{@putResponse}")
		end
	}
	
	arr_of_user_ids_AL2.each { |id|
		if arr_of_discussing_user_ids.include?(id)
			@url = "http://#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/assignments/#{assignment_AL2_id}/submissions/#{id}"
            puts "@url is #{@url}"

            @payload={'submission': {
                                        'posted_grade': 'pass'}
            }
            puts("@payload is #{@payload}")

            @putResponse = HTTParty.put(@url, :body => @payload.to_json, :headers => $header )
            puts(" PUT to grade assignment for user has Response.code #{@putResponse.code} and postResponse is #{@putResponse}")
		else
			@url = "http://#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/assignments/#{assignment_AL2_id}/submissions/#{id}"
            puts "@url is #{@url}"

            @payload={'submission': {
                                        'posted_grade': 'fail'}
            }
            puts("@payload is #{@payload}")

            @putResponse = HTTParty.put(@url, :body => @payload.to_json, :headers => $header )
            puts(" PUT to grade assignment for user has Response.code #{@putResponse.code} and postResponse is #{@putResponse}")
		end
	}
end

##########################################

al1_id = get_group_set_id("Active listener group 1")
al2_id = get_group_set_id("Active listener group 2")
al_id = get_group_set_id("Active listener group")

groups = get_groups_in_group_set(al_id)

groups.each do |group_info|
    group_date = group_info["name"].split(" ").first
    if $todays_date == group_date
        al1_group_id = get_group_id(al1_id, group_info["name"])
        al2_group_id = get_group_id(al2_id, group_info["name"])
        al_group_id = get_group_id(al_id, group_info["name"])

        arr_of_user_ids_AL1 = get_users_in_group(al1_group_id)
        arr_of_user_ids_AL2 = get_users_in_group(al2_group_id)

        arr_of_user_ids = arr_of_user_ids_AL1 + arr_of_user_ids_AL2

        arr_of_discussing_user_ids = get_discussing_users(al_group_id)

        grade_users(arr_of_discussing_user_ids, arr_of_user_ids_AL1, arr_of_user_ids_AL2)
    end
end