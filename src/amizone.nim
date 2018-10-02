import httpclient
import strutils
import streams
import nimquery
import xmltree
import htmlparser
import cgi
import os
import uri

# Take user id and password from environment variables
var id = encodeUrl(getEnv("AMIZONE_ID"))
var password = encodeUrl(getEnv("AMIZONE_PASS"))

# Function for setting the cookie for next request from the current response 
proc setCookieFrom(header: var HttpHeaders, response: Response) = 
    header["Cookie"] = $header["Cookie"] & response.headers["Set-Cookie"].split(";")[0] & ";"

let user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36"
var client = newHttpClient(maxRedirects = 0, userAgent  = user_agent)

# Get initial cookies
var response = client.request("https://amizone.net", "GET")

var headers = newHttpHeaders({"Cookie": ""}) 
headers.setCookieFrom(response)

response = client.request("https://amizone.net/amizone/", "GET", headers = headers)
headers.setCookieFrom(response)

# Construct POST body
var document = parseHtml(newStringStream(response.body))

var body = ""
    
for i in document.find_all("input"):
    if i.attr("type") == "text" and i.attr("style") != "display:none;":
        body.add(i.attr("id") & "=" & id & "&")
    elif i.attr("type") == "password" and i.attr("style") != "display:none;":
        body.add(i.attr("id") & "=" & password & "&")
    elif i.attr("type") != "checkbox":
        body.add(i.attr("id") & "=" & i.attr("value").encodeUrl() & "&")

body.add("ImgBttn_Login.x" & "=" & "0" & "&")
body.add("ImgBttn_Login.y" & "=" & "0")

# Referer & Content-Type headers are required
headers.add("Referer", "https://amizone.net/amizone/")
headers.add("Content-Type", "application/x-www-form-urlencoded" )

# Try to Login
response = client.request("https://amizone.net/amizone/Index.aspx", "POST", headers = headers, body = body)

# Assuming that we are logged in, get the final cookies which now need to go with every request
headers.setCookieFrom(response)

# We are logged in, so GET the home page
response = client.request("https://amizone.net/amizone/WebForms/Home.aspx", "GET", headers = headers)
echo response.body