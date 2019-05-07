require 'httparty'
require 'json'
require 'time'
require 'date'
require 'nitlink'

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

# today's date and time
$todays_date = Date.today.to_s
$time = Time.new.strftime("%k:%M")
time_in_thirty_minutes = Time.now + 60*30
# ugly solution
$time_in_thirty_minutes = time_in_thirty_minutes.strftime("%k:%M")
 
# link parser for paginated get requests
$link_parser = Nitlink::Parser.new

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

    @url = "http://#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/group_categories?per_page=1"
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
def get_group_id(group_set_id, splitted_group_name)
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
                if group_data_info["name"] == splitted_group_name
                    return group_id = group_data_info["id"]  
                end
            end
        }
    else
        group_data = @getResponse.parsed_response
        group_id = nil
    
        group_data.each do |group_data_info|
            if group_data_info["name"] == splitted_group_name
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

#### Move an array of users to a given group ####
def move_users_to_group(group_id, arr_of_user_ids)
    arr_of_user_ids.each { |id|
      @url = "http://#{$canvas_host}/api/v1/groups/#{group_id}/memberships"
      puts "@url is #{@url}"
  
      @payload={'user_id': id}
      puts("@payload is #{@payload}")
  
      @postResponse = HTTParty.post(@url, :body => @payload.to_json, :headers => $header )
      puts(" POST to move user to group has Response.code #{@postResponse.code} and postResponse is #{@postResponse}")
    }
end

##########################################

#### Returns an array of user ids ####
def get_arr_of_user_ids(arr_of_user_names)
    arr_of_user_ids = Array.new

    arr_of_user_names.each { |name|
      @url = "http://#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/users"
      puts "@url is #{@url}"
  
      @payload={'search_term': name}
      puts("@payload is #{@payload}")
  
      @getResponse = HTTParty.get(@url, :body => @payload.to_json, :headers => $header)
      puts(" GET to get user has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")
  
      user_data = @getResponse.parsed_response
      
      user_data.each do |user_data_info|
        arr_of_user_ids.push user_data_info["id"]
      end
    }
  
    return arr_of_user_ids
end

##########################################

#### Returns a user id ####
def get_user_id(full_user_name)
    @url = "http://#{$canvas_host}/api/v1/courses/#{$canvas_course_id}/users"
    puts "@url is #{@url}"
  
    @payload={'search_term': full_user_name}
    puts("@payload is #{@payload}")
  
    @getResponse = HTTParty.get(@url, :body => @payload.to_json, :headers => $header)
    puts(" GET to get user has Response.code #{@getResponse.code} and getResponse is #{@getResponse}")
  
    user_data = @getResponse.parsed_response
    user_id = nil

    user_data.each do |user_info|
        if user_info["name"] == full_user_name
            user_id = user_info["id"]
        end
    end

    return user_id
end

##########################################

al1_id = get_group_set_id("Active listener group 1")
al2_id = get_group_set_id("Active listener group 2")
al_id = get_group_set_id("Active listener group")

groups = get_groups_in_group_set(al_id)

groups.each { |group_info|
    group_info.each do |group|
        splitted_group_name = group["name"].split(" | ")
        group_date = nil
        group_time = nil
        author1 = nil
        author2 = nil

        if splitted_group_name.length == 3
            group_date = splitted_group_name[0]
            group_time_string = splitted_group_name[1]
            author1 = splitted_group_name[2]
        else
            group_date = splitted_group_name[0]
            group_time_string = splitted_group_name[1]
            author1 = splitted_group_name[2]
            author2 = splitted_group_name[3]
        end
        group_time = Time.parse(group_time_string).strftime("%k:%M")
        
        if $todays_date == group_date && group_time.between?($time, $time_in_thirty_minutes) && group["members_count"] == 0
            al1_group_id = get_group_id(al1_id, group["name"])
            al2_group_id = get_group_id(al2_id, group["name"])
            al_group_id = get_group_id(al_id, group["name"])
            
            arr_of_user_ids_AL1 = get_users_in_group(al1_group_id)
            arr_of_user_ids_AL2 = get_users_in_group(al2_group_id)

            arr_of_user_ids = arr_of_user_ids_AL1 + arr_of_user_ids_AL2
            
            if author2 == nil
                arr_of_user_ids.append(get_user_id(author1))
            else
                arr_of_user_ids.append(get_user_id(author1)) 
                arr_of_user_ids.append(get_user_id(author2))
            end

            move_users_to_group(al_group_id, arr_of_user_ids)
        end
    end
}