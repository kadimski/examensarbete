require 'httparty'
require 'json'

canvas_url = "http://canvas.docker/"
canvas_token = "RTIRVP4dcCJoy21JlgOmFrv0UPl7EyrPQFJ8lmlfVNeQVpDQ8p1Q4jllLk3sOL8U"
canvas_course_id = "4"


##### Lista alla group sets ##### 
list_group_sets = HTTParty.get(
    "#{canvas_url}/api/v1/courses/#{canvas_course_id}/group_categories",
    headers: { "authorization" => "Bearer #{canvas_token}" }
)

group_set_data = list_group_sets.parsed_response

al1_id = nil 
al2_id = nil
al_id = nil

group_set_data.each do |group_set_info|
    if group_set_info["name"] == "AL1"
        al1_id = group_set_info["id"]  
    elsif group_set_info["name"] == "AL2"
        al2_id = group_set_info["id"]
    else
        al_id = group_set_info["id"]
    end
end

##################################

##### Hitta AL1 AL2 och AL gruppers id #####

list_groups_in_AL1 = HTTParty.get(
    "#{canvas_url}/api/v1/group_categories/#{al1_id}/groups",
    headers: { "authorization" => "Bearer #{canvas_token}" }
)

list_groups_in_AL2 = HTTParty.get(
    "#{canvas_url}/api/v1/group_categories/#{al2_id}/groups",
    headers: { "authorization" => "Bearer #{canvas_token}" }
)

list_groups_in_AL = HTTParty.get(
    "#{canvas_url}/api/v1/group_categories/#{al_id}/groups",
    headers: { "authorization" => "Bearer #{canvas_token}" }
)

group_data = list_groups_in_AL1.parsed_response

group_data.each do |group_data_info|
    if group_data_info["name"] == "sem1" # detta ska vara ett namn på seminariumet
        AL1_group_id = group_data_info["id"]  
    end
end

group_data = list_groups_in_AL2.parsed_response

group_data.each do |group_data_info|
    if group_data_info["name"] == "sem1" # detta ska vara ett namn på seminariumet
        AL2_group_id = group_data_info["id"] 
    end 
end

group_data = list_groups_in_AL.parsed_response

group_data.each do |group_data_info|
    if group_data_info["name"] == "sem1" # detta ska vara ett namn på seminariumet
        AL_group_id = group_data_info["id"] 
    end 
end

##################################

#### Hitta AL1 och AL2 medlemmars id och gruppera i arrayer ####

list_users_in_AL1_group = HTTParty.get(
    "#{canvas_url}/api/v1/groups/#{AL1_group_id}/users",
    headers: { "authorization" => "Bearer #{canvas_token}" }
)

list_users_in_AL2_group = HTTParty.get(
    "#{canvas_url}/api/v1/groups/#{AL2_group_id}/users",
    headers: { "authorization" => "Bearer #{canvas_token}" }
)

user_data = list_users_in_AL1_group.parsed_response

arr_of_user_ids_AL1 = Array.new
arr_of_user_ids_AL2 = Array.new

user_data.each do |user_data_info|
    arr_of_user_ids_AL1.push user_data_info["id"]
end 

user_data = list_users_in_AL2_group.parsed_response

user_data.each do |user_data_info|
    arr_of_user_ids_AL2.push user_data_info["id"]
end 

arr_of_user_ids = arr_of_user_ids_AL1 + arr_of_user_ids_AL2

###############################

#### Flytta medlemmar från AL1 och AL2 till AL ####

arr_of_user_ids.each { |id|
    populate_AL_group = HTTParty.post(
        "#{canvas_url}/api/v1/groups/#{AL_group_id}/memberships",
        headers: { "authorization" => "Bearer #{canvas_token}" },
        body: {
            user_id: id
        }    
    )
}

###############################

#### Hitta alla disukssionsinlägg och användare ####

list_discussion_topics = HTTParty.get(
    "#{canvas_url}/api/v1/groups/#{AL_group_id}/discussion_topics",
    headers: { "authorization" => "Bearer #{canvas_token}" }
)

al_discussion_data = list_discussion_topics.parsed_response

al_discussion_id = nil

al_discussion_data.each do |al_discussion_info|
    al_discussion_id = al_discussion_info["id"]
end

list_discussion_entries = HTTParty.get(
    "#{canvas_url}/api/v1/groups/#{AL_group_id}/discussion_topics/#{al_discussion_id}/entries",
    headers: { "authorization" => "Bearer #{canvas_token}" }
)

discussion_entries_data = list_discussion_entries.parsed_response

arr_of_discussion_user_ids = Array.new

discussion_entries_data.each do |discussion_entries_info|
    arr_of_discussion_user_ids.push discussion_entries_info["user_id"]
end

##########################################

#### Bedöm dom som har skrivit inlägg ####

list_assignments = HTTParty.get(
    "#{canvas_url}/api/v1/courses/#{canvas_course_id}/assignments",
    headers: { "authorization" => "Bearer #{canvas_token}" }
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

arr_of_discussion_user_ids.each { |id|
    if arr_of_user_ids_AL1.include?(id)
        grade_student = HTTParty.put(
            "#{canvas_url}/api/v1/courses/#{canvas_course_id}/assignments/#{assignment_AL1_id}/submissions/#{id}",
            headers: { "authorization" => "Bearer #{canvas_token}" },
            body: {
                "submission[posted_grade]" =>  "pass"
            }
        )
        puts grade_student.parsed_response
    elsif arr_of_user_ids_AL2.include?(id)
        grade_student = HTTParty.put(
            "#{canvas_url}/api/v1/courses/#{canvas_course_id}/assignments/#{assignment_AL2_id}/submissions/#{id}",
            headers: { "authorization" => "Bearer #{canvas_token}" },
            body: {
                "submission[posted_grade]" => "pass"
            }
        )
        puts grade_student.parsed_response
    else
        puts "Something went wrong"
    end
}