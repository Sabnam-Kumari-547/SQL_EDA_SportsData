
create database Olympics;

use Olympics;

select * from AthleteEventsData;
select * from nocRegionsData;

--joining data--
select ad.*,nd.region,nd.notes from AthleteEventsData as ad
join nocRegionsData as nd 
on ad.NOC=nd.NOC;

-- queries related to data--
1. How many olympics games have been held?

    select count(distinct Games) as total_olympic_games
    from AthleteEventsData;

2. List down all Olympics games held so far? (Data issue at 1956-"Summer"-"Stockholm")

    select distinct ad.year,ad.season,ad.city
    from AthleteEventsData ad
    order by year;

3. Mention the total no of nations who participated in each olympics game?

    with all_countries as
        (select Games, nd.region
        from AthleteEventsData ad
        join nocRegionsData nd ON nd.NOC = ad.NOC
        group by Games, nd.region)
    select games, count(1) as total_countries
    from all_countries
    group by games
    order by games;

4. Which year saw the highest and lowest no of countries participating in olympics?

      with all_countries as
              (select games, nd.region
              from AthleteEventsData ad
              join nocRegionsData nd ON nd.NOC=ad.NOC
              group by games, nd.region),
          tot_countries as
              (select games, count(1) as total_countries
              from all_countries
              group by games)
      select distinct
      concat(first_value(games) over(order by total_countries)
      , ' - '
      , first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
      concat(first_value(games) over(order by total_countries desc)
      , ' - '
      , first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
      from tot_countries
      order by 1;

5. Which nation has participated in all of the olympic games?
      with tot_games as
              (select count(distinct games) as total_games
              from AthleteEventsData),
          countries as
              (select games, nd.region as country
              from AthleteEventsData ad
              join nocRegionsData nd ON nd.NOC=ad.NOC
              group by games, nd.region),
          countries_participated as
              (select country, count(1) as total_participated_games
              from countries
              group by country)
      select cp.*
      from countries_participated cp
      join tot_games tg on tg.total_games = cp.total_participated_games
      order by 1;

6. Identify the sport which was played in all summer olympics?
      with t1 as
          	(select count(distinct games) as total_games
          	from AthleteEventsData where season = 'Summer'),
          t2 as
          	(select distinct games, sport
          	from AthleteEventsData where season = 'Summer'),
          t3 as
          	(select sport, count(1) as no_of_games
          	from t2
          	group by sport)
      select *
      from t3
      join t1 on t1.total_games = t3.no_of_games;

7. Which Sports were just played only once in the olympics?
      with t1 as
          	(select distinct games, sport
          	from AthleteEventsData),
          t2 as
          	(select sport, count(1) as no_of_games
          	from t1
          	group by sport)
      select t2.*, t1.games
      from t2
      join t1 on t1.sport = t2.sport
      where t2.no_of_games = 1
      order by t1.sport;

8. Fetch the total no.of sports played in each olympic games?
      with t1 as
      	(select distinct games, sport
      	from AthleteEventsData),
        t2 as
      	(select games, count(1) as no_of_sports
      	from t1
      	group by games)
      select * from t2
      order by no_of_sports desc;

9. Who is the oldest athletes to win a gold medal?
    with temp as
            (select name,sex,cast(case when age = 'NA' then '0' else age end as int) as age
              ,team,games,city,sport, event, medal
            from AthleteEventsData),
        ranking as
            (select *, rank() over(order by age desc) as rnk
            from temp
            where medal='Gold')
    select *
    from ranking
	where rnk=1;

10. What is the the Ratio of male to female athletes participated in all olympic games? 
    with t1 as
	         (select distinct name,sex 
			 from AthleteEventsData)
	         select round(cast(sum(case 
			                           when sex ='M' then 1 else 0 end)as float)/count(*),3)as male_ratio,
	                round(cast(sum(case 
					                   when sex ='F' then 1 else 0 end )as float)/count(*),3)as female_ratio,
	 count(*)as to_cnt 
	 from t1;
   

11. List down the Top 5 athletes who have won the most gold medals?
    with t1 as
            (select top (5)percent name, team, count(1) as total_gold_medals
            from AthleteEventsData
            where medal = 'Gold'
            group by name, team
            order by total_gold_medals desc),
        t2 as
            (select *, dense_rank() over (order by total_gold_medals desc) as rnk
            from t1)
    select name, team, total_gold_medals
    from t2
    where rnk <= 5;

12. List down the Top 5 athletes who have won the most medals (gold/silver/bronze)?
    with t1 as
            (select top (5) percent name, team, count(1) as total_medals
            from AthleteEventsData
            where medal in ('Gold', 'Silver', 'Bronze')
            group by name, team
            order by total_medals desc),
        t2 as
            (select *, dense_rank() over (order by total_medals desc) as rnk
            from t1)
    select name, team, total_medals
    from t2
    where rnk <= 5;

13. List down the Top 5 most successful countries in olympics? (Success is defined by no of medals won)
    with t1 as
            (select top (5)percent nd.region, count(1) as total_medals
            from AthleteEventsData ad
            join nocRegionsData nd on nd.NOC = ad.NOC
            where medal <> 'NA'
            group by nd.region
            order by total_medals desc),
        t2 as
            (select *, dense_rank() over(order by total_medals desc) as rnk
            from t1)
    select *
    from t2
    where rnk <= 5;
	
14. Identify which country won the most gold, most silver, and most bronze medals in each Olympic game?

    with t1(games,region,no_gold,no_silver,no_bronze)
	as (select games,region,SUM(CASE WHEN medal = 'gold' THEN 1 ELSE 0 END)as no_gold,
	                        SUM(CASE WHEN medal = 'silver' THEN 1 ELSE 0 END)as no_silver,
	                        SUM(CASE WHEN medal = 'bronze' THEN 1 ELSE 0 END)as no_bronze
	from AthleteEventsData  ad
	join nocRegionsData nd
	on ad.NOC=nd.NOC
	group by games,region)

	select distinct games,
	concat((first_value (region) over(partition by games order by no_gold desc)),
	' - ',first_value (no_gold) over(partition by games order by no_gold desc)) as max_gold,
	concat((first_value (region) over(partition by games order by no_silver desc)),
	' - ',first_value (no_silver) over(partition by games order by no_silver desc)) as max_silver,
	concat((first_value (region) over(partition by games order by no_bronze desc)),
	' - ',first_value (no_bronze) over(partition by games order by no_bronze desc)) as max_bronze
  from t1
  order by games;

15. In which Sport/event, did India win its highest medals?

  with t1 as (
               select sport,region,total_no_of_medal,
               dense_rank() over(partition by region order by total_no_of_medal desc) as new_rank
  from( 
       select sport,region,SUM(CASE WHEN medal in('gold','silver','bronze')THEN 1 ELSE 0 END )as total_no_of_medal
  from AthleteEventsData ad
  join nocRegionsData nd
  on ad.NOC=nd.NOC
  group by sport,region)sub)

  select sport,region,total_no_of_medal
  from t1 
  where new_rank=1 and region='India';

  --Key Insights of the given data related to the Olympics--

   From  the above analysis, we can conclude that:-

       1.There have been a total of 51 Olympic games from 1896–2016.

       2.France, Italy, Switzerland, and UK have participated in all Olympic games from 1896–2016.

       3.The Oldest Athletes to win a gold medal are Charles Jacobus and Oscar Gomer Swahn at the age of 64.

       4.Michael Fred Phelps has won the most medals in Olympic history.

       5.The most successful country in the Olympics is the USA with a total of 5637 medals.

       6.India won its highest Olympic medal in Hockey with 173 medals.

	
	
  
   

