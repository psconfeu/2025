using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using Flurl;
using Flurl.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;

namespace Sleet.Search
{
    public static class Query
    {
        /// <summary>
        /// {source} must be the url encoded path to the static search resource {feed}/search/query
        /// 
        /// Possible query parameters from nuget:
        /// q
        /// skip
        /// take
        /// prerelease
        /// includeDelisted
        /// supportedFramework
        /// packageTypeFilter (multiple)
        /// semVerLevel=2.0.0
        /// </summary>
        [FunctionName("Query")]
        public static async Task<IActionResult> Run(
                    [HttpTrigger(AuthorizationLevel.Function, "get", Route = "search/source/{source}/query")] HttpRequest req, string source, ILogger log)
        {
            var sourceUrl = new Url(HttpUtility.UrlDecode(source));
            var query = req.Query["q"];
            var skip = 0;
            var take = 100;
            var prerelease = !StringComparer.OrdinalIgnoreCase.Equals(req.Query["prerelease"], "false");

            if (int.TryParse(req.Query["skip"], out var skipNum) && skipNum > -1)
            {
                skip = skipNum;
            }

            if (int.TryParse(req.Query["take"], out var takeNum) && takeNum > 0)
            {
                take = takeNum;
            }

            // Read static search results
            var response = await sourceUrl.GetAsync();
            if (response.StatusCode == 200)
            {
                try
                {
                    // Parse static search results
                    var json = await SearchUtils.ReadJson(await response.GetStreamAsync());

                    var entries = SearchUtils.GetEntries(json);
                    var terms = SearchUtils.GetTerms(query);

                    // Filter on prerel and modify results to remove prerel packages
                    entries = SearchUtils.FilterOnPreRel(entries, prerelease);

                    // Filter on search terms if given
                    var searchResults = SearchUtils.SearchEntries(entries, terms);

                    // Apply skip/take
                    var toAdd = searchResults.Skip(skip).Take(take).ToList();

                    // Build response
                    var result = SearchUtils.GetSearchResult(toAdd, searchResults.Count, (JObject)json["@context"]);

                    return new OkObjectResult(result);
                } 
                catch (Exception ex)
                {
                    Console.WriteLine(ex);
                    return new StatusCodeResult(500);
                }
            }

            return new StatusCodeResult(response.StatusCode);
        }
    }
}