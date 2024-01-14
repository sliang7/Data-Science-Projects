###Background and Analysis###
In this project that I completed for my CIS9760 (Big Data Technologies) class at Baruch College - under Prof. Ecem Basak - I loaded and analyzed a dataset 
from the NYC OpenData website: https://data.cityofnewyork.us/. To do so, I wrote a Python script that runs in Docker to consume data from the website. 
The script then pushed the data into an OpenSearch cluster provisioned via Amazon Web Services (AWS). Once the data was loaded, I created four 
visualizations to better explain and understand it.
This particular dataset contains 8.69 million rows of information regarding fire incident dispatches; the dataset has 29 columns. 
After loading the entire dataset, less the rows that are filtered out*, I set out to answer the following four questions:
*Note: The final number of rows ended up being 8,004,412.

1. What is the average incident response time per borough?

Answer: From visual01.png, we see that Queens had the highest average incident response time out of all five boroughs, 
with an average time of 279.949 seconds.
The Bronx had an average time of 275.755 seconds.
Richmond/Staten Island had an average time of 271.79 seconds.
Manhattan had an average time of 260.304 seconds.
Brooklyn had the lowest average incident response time of 243.876 seconds.

2. Which zip codes had the highest number of fire incidents? (I provide the top 5 in the answer.)

Answer: From visual02.png, we see that zip codes 10456, 11212, 10029, 11207, and 10002 had the highest number of
fire incidents. 10456 had 128,347 fire incidents. 11212 had 123,736 incidents. 10029 had 122,373 incidents. 
11207 had 117,928 incidents. And 10002 had 107,275 incidents.
Notably, 10456 (a neighborhood in The Bronx), the zip code with the highest number of fire incidents has a median household income of 
$16,664 which is significantly lower than the US average of $56,604 (Source:http://www.neighborhoodlink.com/zip/10456).
Likewise, 11212 (a neighborhood in Brooklyn), the zip code with the second highest number, has a median household income of 
$20,839, which is also significantly lower than the US average.
As an idea for a future project, if we could connect nationwide median household income data to this fire incident dataset, it would be 
interesting to examine if this trend holds true for all neighborhoods in the US.

3. What is the relationship between highest alarm level and average incident response time?

Answer: From visual03.png, we see that "fifth alarm or higher" fires had the highest average incident response time of 269.095 seconds.
We also see that sixth alarm fires had the lowest average incident response time of 188.5 seconds. 
Additionally, it would be intuitive to think that seventh alarm fires, which are categorized as more serious than second or third alarm fires, 
would have a quicker average incident response time but we see that their average incident response time is the fourth slowest with
an average of 237.231 seconds. That being said, the difference is only a matter of about five seconds.
However, from this we can conclude that there isn't necessarily a one-to-one correlation between highest
alarm level and average incident response time; that is, the highest alarm level does not always correspond
with the quickest average incident response time.

4. How does the maximum incident response time change over the years? (One would perhaps expect 
incident response time to decrease over the years as technology improves from year to year.)

Answer: From the given data, my expectation can be deemed incorrect. We see from visual04.png that in 2004, the first year for which we have data, 
the maximum incident response time is 1,734 seconds. Then in 2005, the max incident response time is 50,035 seconds. The year with the highest maximum 
is 2011 with a max incident response time of 260,460 seconds. Overall, it seems that this metric is relatively stable, with the year 2011 being an outlier.