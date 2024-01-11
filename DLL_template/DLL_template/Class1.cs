
using System;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.RegularExpressions;

public class APIClient
{
    private HttpClient client;

    public APIClient(string baseUrl)
    {
        client = new HttpClient { BaseAddress = new Uri(baseUrl) };
    }

    public string Get(string endpoint, bool convertHtmlToText = false)
    {
        try
        {
            HttpResponseMessage response = client.GetAsync(endpoint).Result; // Use .Result to block until the GET request is complete

            if (response.IsSuccessStatusCode)
            {
                if (convertHtmlToText)
                {
                    return ConvertHtmlToText(response.Content.ReadAsStringAsync().Result);
                }
                return response.Content.ReadAsStringAsync().Result; // Use .Result to block until content is read
            }
            else
            {
                throw new Exception("Failed to GET data from " + endpoint + ". Status Code: " + response.StatusCode);
            }
        }
        catch (Exception ex)
        {
            return "{{\"error\": \"Error: " + ex.Message + "\"}}";
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