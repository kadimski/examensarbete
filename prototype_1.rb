require 'httparty'
require 'json'

$canvas_url = "http://canvas.docker/"
$canvas_token = "RTIRVP4dcCJoy21JlgOmFrv0UPl7EyrPQFJ8lmlfVNeQVpDQ8p1Q4jllLk3sOL8U"
$canvas_course_id = "4"


##### Returns the group set id for a given group set #####
def get_group_set_id(group_set_name) 
    list_group_sets = HTTParty.get(
        "#{$canvas_url}/api/v1/courses/#{$canvas_course_id}/group_categories",
        headers: { "authorization" => "Bearer #{$canvas_token}" }
    )

    group_set_data = list_group_sets.parsed_response
    group_set_id = nil 

    group_set_data.each do |group_set_info|
        if group_set_info["name"] == group_set_name
            group_set_id = group_set_info["id"]  
        end
    end

    return group_set_id
end
##################################

$al1_id = get_group_set_id("AL1")
$al2_id = get_group_set_id("AL2")
$al_id = get_group_set_id("AL")

##### Returns the group id for a given group name in a group set #####
def get_group_id(group_set_id, group_name)
    list_groups_in_group_set = HTTParty.get(
        "#{$canvas_url}/api/v1/group_categories/#{group_set_id}/groups",
        headers: { "authorization" => "Bearer #{$canvas_token}" }
    )

    group_data = list_groups_in_group_set.parsed_response
    group_id = nil

    group_data.each do |group_data_info|
        if group_data_info["name"] == group_name
            group_id = group_data_info["id"]  
        end
    end

    return group_id
end
##################################

$al1_group_id = get_group_id($al1_id, "sem1")
$al2_group_id = get_group_id($al2_id, "sem1")
$al_group_id = get_group_id($al_id, "sem1")

#### Returns an array of user ids from a given group ####
def get_users_in_group(group_id)
    list_users_in_group = HTTParty.get(
        "#{$canvas_url}/api/v1/groups/#{group_id}/users",
        headers: { "authorization" => "Bearer #{$canvas_token}" }
    )

    user_data = list_users_in_group.parsed_response

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
        populate_group = HTTParty.post(
            "#{$canvas_url}/api/v1/groups/#{group_id}/memberships",
            headers: { "authorization" => "Bearer #{$canvas_token}" },
            body: {
                user_id: id
            }    
        )
    }
end

###############################

move_users_to_group($al_group_id, $arr_of_user_ids)

#### Returns an array of user ids who have participated in the discussion, assuming only one discussion in a group ####

def get_discussing_users(group_id)
    list_discussion_topics = HTTParty.get(
        "#{$canvas_url}/api/v1/groups/#{group_id}/discussion_topics",
        headers: { "authorization" => "Bearer #{$canvas_token}" }
    )

    discussion_data = list_discussion_topics.parsed_response
    discussion_id = nil

    discussion_data.each do |discussion_info|
        discussion_id = discussion_info["id"]
    end

    list_discussion_entries = HTTParty.get(
        "#{$canvas_url}/api/v1/groups/#{group_id}/discussion_topics/#{discussion_id}/entries",
        headers: { "authorization" => "Bearer #{$canvas_token}" }
    )

    discussion_entries_data = list_discussion_entries.parsed_response
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
    list_assignments = HTTParty.get(
        "#{$canvas_url}/api/v1/courses/#{$canvas_course_id}/assignments",
        headers: { "authorization" => "Bearer #{$canvas_token}" }
    )

    assignments_data = list_assignments.parsed_response
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
            grade_student = HTTParty.put(
                "#{$canvas_url}/api/v1/courses/#{$canvas_course_id}/assignments/#{assignment_AL1_id}/submissions/#{id}",
                headers: { "authorization" => "Bearer #{$canvas_token}" },
                body: {
                    "submission[posted_grade]" =>  "pass"
                }
            )
            puts grade_student.parsed_response
        elsif $arr_of_user_ids_AL2.include?(id)
            grade_student = HTTParty.put(
                "#{$canvas_url}/api/v1/courses/#{$canvas_course_id}/assignments/#{assignment_AL2_id}/submissions/#{id}",
                headers: { "authorization" => "Bearer #{$canvas_token}" },
                body: {
                    "submission[posted_grade]" => "pass"
                }
            )
            puts grade_student.parsed_response
        else
            puts "Something went wrong"
        end
    }
end

grade_users(arr_of_discussing_user_ids)

##########################################