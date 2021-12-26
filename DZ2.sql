-- 1. вывести количество фильмов в каждой категории, отсортировать по убыванию.
select 
	 fc.category_id 
	,c.name
	,count(fc.film_id) FLM_QTY
from film_category fc 
left join category c on c.category_id  = fc.category_id 
group by 
	 c.name
	,fc.category_id
order by 3 desc ;

--2. вывести 10 актеров, чьи фильмы большего всего арендовали, отсортировать по убыванию.

select 
	 concat(a.first_name,' ',a.last_name, '(' , a.actor_id, ')' ) actor_name
	,sum(t1.Rent_QTY) Rent_QTY
from (	select 
			  i.film_id
			, count(r.rental_id)  Rent_QTY
		from inventory i  
		left join rental r on i.inventory_id = r.inventory_id 
		group by 
			  i.film_id  ) as t1
left join film_actor fa on t1.film_id = fa.film_id 
left join actor a on fa.actor_id = a.actor_id 
group by  
	concat(a.first_name,' ',a.last_name, '(' , a.actor_id, ')' )
order by 2 desc ;

--3. вывести категорию фильмов, на которую потратили больше всего денег.
select 
	 t.calegory_id
	,c."name" 
	,t.amount
from (	select 
			(select fc.category_id 
				from film_category fc 
				where fc.film_id  = (select i.film_id 
										from inventory i 
										where i.inventory_id = r.inventory_id ) ) calegory_id
			,sum(p.amount) amount
		from payment p 
		left join rental r on p.rental_id  = r.rental_id 
		group by 
			(select fc.category_id 
				from film_category fc 
				where fc.film_id  = (select i.film_id 
										from inventory i 
										where i.inventory_id = r.inventory_id )	)	) t
left join category c on t.calegory_id = c.category_id 
order by 3 desc ;

--4. вывести названи€ фильмов, которых нет в inventory. Ќаписать запрос без использовани€ оператора IN.
select 
	 f.film_id 
	,f.title 
from film f 
left join inventory i on f.film_id = i.film_id 
where i.inventory_id is null ;

--5. вывести топ 3 актеров, которые больше всего по€вл€лись в фильмах в категории УChildrenФ. ≈сли у нескольких актеров одинаковое кол-во фильмов, вывести всех.
with T as (
	select 
		 fa.actor_id 
		,concat(a.first_name, ' ', a.last_name)  actor
		,count (t.film_id) film_qty
		,rank () over (order by count (t.film_id) desc) r_all
	from (  select 
				 f.film_id  
			from film f 
			left join film_category fc ON f.film_id = fc.film_id 
			left join category c ON c.category_id = fc.category_id 
			where c."name"  ='Children' ) t
	left join film_actor fa on t.film_id = fa.film_id 
	left join actor a on fa.actor_id = a.actor_id 
	group by fa.actor_id , concat(a.first_name, ' ', a.last_name)	)
select 
	 t.actor_id
	,t.actor
	,t.film_qty
	,t.r_all
from t
where t.r_all<=3;

--6. вывести города с количеством активных и неактивных клиентов (активный Ч customer.active = 1). ќтсортировать по количеству неактивных клиентов по убыванию.
select 
	 a.city_id	
	,c1.city 	
	,c.active
	,count(c.customer_id  )customer_QTY
from customer c 
left join address 	a 	on c.address_id = a.address_id 
left join city 		c1 	on a.city_id = c1.city_id
group by 	 
	 a.city_id	
	,c1.city 	
	,c.active
order by 3 asc, 4 desc ;

--7. вывести категорию фильмов, у которой самое большое кол-во часов суммарной аренды в городах (customer.address_id в этом city), 
		--и которые начинаютс€ на букву УaФ. “о же самое сделать дл€ городов в которых есть символ У-Ф. Ќаписать все в одном запрос

with t as (
	select 
		 cat."name" category	
		,ct.city 
		,case 
			when lower(substring(ct.city,1,1)) = 'a' then 'Y'  
		 end GR_A
		,case 
			when ct.city like '%-%' then 'Y'
		 end GR_Minus
		,r.return_date -r.rental_date  dt_dur
	from rental r 
	left join inventory i on r.inventory_id = i.inventory_id 
	left join customer c on r.customer_id = c.customer_id 
	left join address a on c.address_id = a.address_id 
	left join city ct on a.city_id = ct.city_id 
	left join film f on i.film_id = f.film_id 
	left join film_category fc on i.film_id = fc.film_id 
	left join category cat on fc.category_id = cat.category_id 
)
, t1 as (
	select 
		 t.category
		,t.dt_dur
		,'gr_a' gr
	from t
	where t.GR_A is not null 
	Union all
	select 
		 t.category
		,t.dt_dur
		,'gr_m'
	from t
	where t.GR_Minus is not null
)
, t2 as (
select 
	 t1.category
	,t1.gr
 	,sum(t1.dt_dur) 
 	,rank() over (partition by t1.gr  order by sum(t1.dt_dur) desc) 
from t1
group by 
	 t1.category
	,t1.gr
)
select 
* from t2
where t2.rank = 1
;