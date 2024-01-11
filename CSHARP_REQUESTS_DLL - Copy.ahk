#Requires Autohotkey v2
#Include <CLR>
c := "
(
using System;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.RegularExpressions;
using System.Threading;
using System.Collections.Generic;

public class APIClient
{
    private HttpClient client;

    public APIClient(string baseUrl, bool followRedirects = true)
    {
        var handler = new HttpClientHandler
        {
            AllowAutoRedirect = followRedirects
        };
        client = new HttpClient(handler) { BaseAddress = new Uri(baseUrl) };
    }

    public string Get(string endpoint, TimeSpan? timeout = null, string path = null, bool convertHtmlToText = false, Dictionary<string, string> headers = null, bool returnAsStream = false)
    {
        try
        {
            if (timeout.HasValue)
            {
                client.Timeout = timeout.Value;
            }

            var request = new HttpRequestMessage(HttpMethod.Get, endpoint);

            // Add any headers to the request
            if (headers != null)
            {
                foreach (var header in headers)
                {
                    request.Headers.Add(header.Key, header.Value);
                }
            }

            HttpResponseMessage response = client.SendAsync(request).Result; // Use .Result to block until the GET request is complete

            if (response.IsSuccessStatusCode)
            {
                if (returnAsStream)
                {
                    // Caller needs to manage the stream's lifecycle (i.e. disposing it correctly)
                    Stream responseStream = response.Content.ReadAsStreamAsync().Result;

                    if (!string.IsNullOrEmpty(path))
                    {
                        using (var fileStream = File.Create(path))
                        {
                            responseStream.CopyTo(fileStream);
                        }

                        // Reset the stream position after writing to file if the stream supports seeking
                        if (responseStream.CanSeek)
                        {
                            responseStream.Position = 0;
                        }

                        return path; // Return the path to indicate where the file was saved
                    }

                    // If a path is not provided, return an empty string since we can't return a stream through a string method.
                    return string.Empty;
                }
                else
                {
                    string contentString = response.Content.ReadAsStringAsync().Result; // Use .Result to block until content is read

                    if (convertHtmlToText)
                    {
                        contentString = ConvertHtmlToText(contentString);
                    }

                    if (!string.IsNullOrEmpty(path))
                    {
                        File.WriteAllText(path, contentString);
                    }

                    return contentString;
                }
            }
            else
            {
                throw new Exception("Failed to GET data from " + endpoint + ". Status Code: " + response.StatusCode);
            }
        }
        catch (Exception ex)
        {
            return "{\"error\": \"Error: " + ex.Message + "\"}";
        }
    }

    private string ConvertHtmlToText(string html)
    {
        // A rudimentary conversion from HTML to text:
        // Disclaimer: This is a very basic conversion; proper HTML to text conversion requires HTML parsing.
        string text = Regex.Replace(html, "<style>(.|\n)*?</style>", string.Empty);
        text = Regex.Replace(text, "<script>(.|\n)*?</script>", string.Empty);
        text = Regex.Replace(text, "<.*?>", string.Empty);
        text = WebUtility.HtmlDecode(text);
        text = text.Replace("\r\n", "\n").Replace("\n", Environment.NewLine); // Normalize newlines
        return text;
    }


    public string Post(string endpoint, string data)
    {
        try
        {
            var content = new StringContent(data);
            content.Headers.ContentType = new MediaTypeHeaderValue("application/json");

            HttpResponseMessage response = client.PostAsync(endpoint, content).Result; // Use .Result to block until the POST request is complete

            if (response.IsSuccessStatusCode)
            {
                return response.Content.ReadAsStringAsync().Result; // Use .Result to block until content is read
            }
            else
            {
                throw new Exception("Failed to POST data from " + endpoint + ". Status Code: " + response.StatusCode);
            }
        }
        catch (Exception ex)
        {
            return "{{\"error\": \"Error: " + ex.Message + "\"}}";
        }
    }

    public string Put(string endpoint, string data)
    {
        try
        {
            var content = new StringContent(data);
            content.Headers.ContentType = new MediaTypeHeaderValue("application/json");

            HttpResponseMessage response = client.PutAsync(endpoint, content).Result; // Use .Result to block until the PUT request is complete

            if (response.IsSuccessStatusCode)
            {
                return response.Content.ReadAsStringAsync().Result; // Use .Result to block until content is read
            }
            else
            {
                throw new Exception("Failed to PUT data from " + endpoint + ". Status Code: " + response.StatusCode);
            }
        }
        catch (Exception ex)
        {
            return "{{\"error\": \"Error: " + ex.Message + "\"}}";
        }
    }

    public string Delete(string endpoint)
    {
        try
        {
            HttpResponseMessage response = client.DeleteAsync(endpoint).Result; // Use .Result to block until the DELETE request is complete

            if (response.IsSuccessStatusCode)
            {
                return response.Content.ReadAsStringAsync().Result; // Use .Result to block until content is read
            }
            else
            {
                throw new Exception("Failed to DELETE data from " + endpoint + ". Status Code: " + response.StatusCode);
            }
        }
        catch (Exception ex)
        {
            return "{{\"error\": \"Error: " + ex.Message + "\"}}";
        }
    }
}
)"

url := "http://example.com/"

asm := CLR_CompileCS(c, "System.dll | System.Net.Http.dll")
obj := CLR_CreateObject(asm, "APIClient", url)
; headers := Map("Accept", "text/html", "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36")
headers := Map("Accept", "text/html", "User-Agent", "APIClient/1.0")
response := obj.Get("", , true)
Msgbox response