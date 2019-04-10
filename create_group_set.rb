require 'httparty'
require 'json'

canvas_url = "http://canvas.docker/"
canvas_token = "RTIRVP4dcCJoy21JlgOmFrv0UPl7EyrPQFJ8lmlfVNeQVpDQ8p1Q4jllLk3sOL8U"
canvas_course_id = "4"

create_group_set_AL1 = HTTParty.post(
    "#{canvas_url}/api/v1/courses/#{canvas_course_id}/group_categories",
    headers: { "authorization" => "Bearer #{canvas_token}" },
    body: {
        name: "AL1",
        self_signup: "enabled"
    }
)

create_group_set_AL2 = HTTParty.post(
    "#{canvas_url}/api/v1/courses/#{canvas_course_id}/group_categories",
    headers: { "authorization" => "Bearer #{canvas_token}" },
    body: {
        name: "AL2",
        self_signup: "enabled"
    }
)

create_group_set_AL = HTTParty.post(
    "#{canvas_url}/api/v1/courses/#{canvas_course_id}/group_categories",
    headers: { "authorization" => "Bearer #{canvas_token}" },
    body: {
        name: "AL"
    }
)