#!/usr/bin/env bash
function apiCall {
  local url=$1
  local payload=$2
  curl --insecure \
    -u admin:IbwvebaSuhhN5J5vCKqeJAj85eufb3 \
    -X POST \
    ${url} \
    -H "accept: application/json" \
    -H "Content-Type: application/json" \
    -d "${payload}"
}

url=https://harbor.k8s-local.io/api/v2.0
user_payload='{
  "username": "demo",
  "comment": "demo",
  "password": "Demodemo0",
  "realname": "Demo",
  "email": "demo@example.com"
}'

project_payload='{
  "project_name": "demo",
  "metadata": {
    "enable_content_trust": "false",
    "auto_scan": "true",
    "public": "true"
  }
}'

project_member='{
  "role_id": 2,
  "member_user": {
    "username": "demo"
  }
}'

apiCall "${url}/users" "${user_payload}"
apiCall "${url}/projects" "${project_payload}"
apiCall "${url}/projects/2/members" "${project_member}"

(
  cd charts/demo
  helm package ./hello-world
  helmchart=$(ls -1 |grep tgz)
  curl -X POST -H 'Content-Type: multipart/form-data' -F "chart=@${helmchart};type=application/x-compressed-tar" -u "demo:Demodemo0" https://harbor.k8s-local.io/api/chartrepo/demo/charts --insecure
)
