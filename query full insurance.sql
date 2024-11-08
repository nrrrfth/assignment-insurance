--insurance order
WITH ActivePremium AS(
select 
	a.date_start, 
	a.date_end,
	a.user_id, 
	a.order_rank, 
	a.premium, 
	sum(b.premium) as active_premium
from 
	insurance_orders a
left join 
	insurance_orders b 
on 
	a.user_id = b.user_id 
	and b.date_start <= a.date_start 
	and b.date_end >= a.date_start
group by
	a.date_start,
	a.date_end,
	a.user_id, 
	a.order_rank,
	a.premium
)
select  
	date_start, 
	date_end, 
	user_id,
	order_rank, 
	premium, 
	active_premium,
	case
		when active_premium >= 300000 then 'TRUE'
		else 'FALSE'
	end as flag
from 
	ActivePremium
order by 
	user_id,
	order_rank;

--expected repayment amount without no late payment or loan restructure
select 
	lc.contract_id, 
	lc.tenure,
	sum(case when lcl.ledger_type = 'PRINCIPAL'
		and extract (month from lcl.due_date) in (8,9,10) then lcl.balance else 0 end) as total_principal,
	sum(case when lcl.ledger_type = 'INTEREST'
   		and extract (month from lcl.due_date) in (8,9,10) then lcl.balance else 0 end) as total_interest
from 
	loan_contracts lc
join 
	loan_contract_ledgers lcl on lc.contract_id = lcl.contract_id
where 
	lc.contract_status = 'ACTIVE'
group by 
	lc.contract_id, 
	lc.tenure;

-- display latefee amount which has been waived for each contract status
select 
	lc.contract_status,
	sum(lcl.balance) as waived_late_fee
from 
	loan_contracts lc
left join 
	loan_contract_ledgers lcl on lc.contract_id = lcl.contract_id
where
	lcl.ledger_type = 'LATE_FEE' and lcl.ledger_status = 'WAIVED'
group by 
	lc.contract_status
order by 
	lc.contract_status;

--konsistensi antara tabel loan_contracts dgn loan_contract_ledgers
SELECT lc.contract_id
FROM loan_contracts lc
LEFT JOIN loan_contract_ledgers lcl ON lc.contract_id = lcl.contract_id
WHERE lcl.contract_id IS NULL;

--mencari nilai negatif dari loan_amount, provison, interest, principal pada table loan_contracts
SELECT *
FROM loan_contracts
WHERE loan_amount < 0 OR provision < 0 OR interest < 0 OR principal < 0;

--mendeteksi tanggal yang tidak konsisten(tanggal jatuh tempo tidak lebih awal dari tanggal pembayaran)
SELECT *
FROM loan_contract_ledgers
WHERE balance < 0 OR initial_balance < 0;

--query no 1 sebelumnya
select 
	lc.contract_id,
	lc.tenure,
	lc.loan_amount,
	lc.interest, 
	lc.principal,
	sum(case 
			when extract (MONTH from lcl.due_date) in (8,9,10)
	   		and lcl.ledger_type in('PRINCIPAL', 'INTEREST') then lcl.balance
			else 0
		end) as expected_repayment
from 
	loan_contracts lc
left join 
	loan_contract_ledgers lcl on lc.contract_id = lcl.contract_id 
where 
	lc.contract_status = 'ACTIVE'
group by 
	lc.contract_id, 
	lc.tenure, 
	lc.loan_amount, 
	lc.interest, 
	lc.principal
order by 
	lc.contract_id,
	lc.tenure;